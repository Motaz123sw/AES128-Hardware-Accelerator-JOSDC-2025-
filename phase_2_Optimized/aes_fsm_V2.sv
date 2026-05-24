module aes_fsm_V2(
    input  wire        rst,
    input  wire        clk,
    input  wire        start,            // Pulse: Key Expansion Finished
    input  wire        input_fifo_empty,
    input  wire        output_fifo_full,

    input  wire [127:0] round_keys [0:10],
    input  wire [151:0] input_packet,    
    input  wire [127:0] counter,
    input  wire        read_done, 	 // Handshake from Arbiter
	 input  wire         is_eos,

    output reg  [151:0] output_packet,
    output reg         valid,
    output wire         rst_ififo,
    output reg         en_ififo,
    output reg         key_expan_go,
    output reg  [127:0] main_key,
    output reg         new_stream
);

    assign rst_ififo = rst;

    //---------------------------------------
    // Header decode Parameters
    //---------------------------------------
    localparam [2:0]
        MODE_ECB = 3'd0,
        MODE_CTR = 3'd1,
        MODE_CBC = 3'd2,
        MODE_CFB = 3'd3,
        MODE_OFB = 3'd4;

    localparam [2:0]
        CMD_EOS = 3'd0,
        CMD_KEY = 3'd1,
        CMD_PT  = 3'd2,
        CMD_CT  = 3'd3,
        CMD_IV  = 3'd4;

    //---------------------------------------
    // FSM States
    //---------------------------------------
    typedef enum logic [2:0] {
        IDLE, READ, READ_WAIT, START_OP, WAIT_DONE, WRITE_FIFO
    } state_t;

    state_t state, next_state;

    //---------------------------------------
    // Registers
    //---------------------------------------
    reg [7:0]   header_r;
    reg [15:0]  seq_id_r;
    reg [127:0] payload_r;
    reg [127:0] saved_input;
    reg [1:0]   current_stream;
    
    reg [127:0] feedback;       
    reg [127:0] last_ct;
    reg new_stream_delayed; 

    reg enc_start, dec_start;
    reg key_is_valid;

    //---------------------------------------
    // AES cores
    //---------------------------------------
    wire [127:0] enc_out, dec_out;
    wire enc_done, dec_done;

    aes128_encrypt_pipeline enc (
        .clk(clk), .rst(rst), .start(enc_start),
        .block_in(payload_r), .round_keys(round_keys),
        .done(enc_done), .cipher_text(enc_out)
    );

    aes128_decrypt_pipeline dec (
        .clk(clk), .rst(rst), .start(dec_start),
        .block_in(payload_r), .round_keys(round_keys),
        .done(dec_done), .plain_text(dec_out)
    );

    //---------------------------------------
    // Key Validity Logic
    //---------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_is_valid <= 0;
        end else begin
            if (key_expan_go) 
                key_is_valid <= 0;
            else if (start)   
                key_is_valid <= 1;
        end
    end

    //---------------------------------------
    // FSM State Register
    //---------------------------------------
    always @(posedge clk or posedge rst)
        if (rst) state <= IDLE;
        else     state <= next_state;

    //---------------------------------------
    // FSM Next-State Logic
    //---------------------------------------
    always @(*) begin
        next_state = state;
        en_ififo   = 0;

        case (state)
            IDLE:
                if (!input_fifo_empty && !output_fifo_full)
                    next_state = READ;

            READ: begin
                en_ififo   = 1;
                next_state = READ_WAIT;
            end

            READ_WAIT:
                next_state = START_OP;

            START_OP: begin
                if (header_r[2:0] == CMD_KEY) begin
                    next_state = IDLE; 
                end
                else if (header_r[2:0] == CMD_EOS) begin
                    next_state = WRITE_FIFO; 
                end
                else if (header_r[2:0] == CMD_IV) begin
                    next_state = IDLE; 
                end
                else if (key_is_valid) begin 
                    next_state = WAIT_DONE;
                end
            end

            WAIT_DONE:
                if ((header_r[2:0] == CMD_PT && enc_done) ||
                    (header_r[2:0] == CMD_CT && dec_done)
						  || (header_r[2:0] == CMD_CT && enc_done && header_r[5:3] !=  MODE_ECB && header_r[5:3] !=  MODE_CBC))
                    next_state = WRITE_FIFO;

            WRITE_FIFO:
                // FIX: Stay in this state until the arbiter acknowledges receipt
                if (read_done)
                    next_state = (!input_fifo_empty && !output_fifo_full) ? READ : IDLE;
                else
                    next_state = WRITE_FIFO;

            default: next_state = IDLE;
        endcase
    end

    //---------------------------------------
    // Sequential Datapath
    //---------------------------------------
    wire is_new_stream_now = (current_stream != input_packet[151:150]);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            header_r       <= 0;
            seq_id_r       <= 0;
            payload_r      <= 0;
            saved_input    <= 0;
            current_stream <= 2'b11;
            new_stream     <= 0;
				new_stream_delayed <= 0; 
            feedback       <= 0;
            last_ct        <= 0;
            output_packet  <= 0;
            valid          <= 0;
            enc_start      <= 0;
            dec_start      <= 0;
            key_expan_go   <= 0;
            main_key       <= 128'h0;
        end else if (is_eos) begin   //  synchronous reset
				header_r       <= 0;
				seq_id_r       <= 0;
				payload_r      <= 0;
				saved_input    <= 0;
				current_stream <= 2'b11;
				new_stream     <= 0;
				new_stream_delayed <= 0; 
				feedback       <= 0;
				last_ct        <= 0;
				output_packet  <= 0;
				valid          <= 0;
				enc_start      <= 0;
				dec_start      <= 0;
				key_expan_go   <= 0;
				main_key       <= 128'h0;
    end
		  
		  else begin
            enc_start    <= 0;
            dec_start    <= 0;
            key_expan_go <= 0;

            // FIX: Valid is only high during WRITE_FIFO and drops immediately on read_done
            if (state == WRITE_FIFO && !read_done)
                valid <= 1;
            else
                valid <= 0;

            if (state == READ_WAIT) begin
                header_r    <= input_packet[151:144];
                seq_id_r    <= input_packet[143:128];
                saved_input <= input_packet[127:0];

                new_stream     <= is_new_stream_now;
					 new_stream_delayed <= new_stream;
                current_stream <= input_packet[151:150];

                case (input_packet[149:147])
                    MODE_ECB: payload_r <= input_packet[127:0];
                    MODE_CTR: payload_r <= (counter-1); 

                    MODE_CBC:
                        payload_r <= (input_packet[146:144] == CMD_PT)
                                    ? (new_stream ? counter : feedback) ^ input_packet[127:0]
                                    : input_packet[127:0];

                    MODE_CFB:
                        payload_r <= new_stream ? counter : feedback;

                    MODE_OFB:
                        payload_r <= new_stream ? counter : feedback;
                endcase
            end

            if (state == START_OP) begin
                case (header_r[2:0])
                    CMD_KEY: begin
                        key_expan_go <= 1;
                        main_key     <= saved_input; 
                    end
                    
                    CMD_EOS: begin
                        output_packet <= {header_r, seq_id_r, saved_input};
                        feedback <= 0;
                        last_ct  <= 0;
                    end
                    
                    CMD_PT: begin
                        if (key_is_valid) enc_start <= 1;
                    end
                    
                    CMD_CT: begin
                        if (key_is_valid) begin
                            if (header_r[5:3] == MODE_ECB || header_r[5:3] == MODE_CBC)
                                dec_start <= 1;
                            else
                                enc_start <= 1; 
                        end
                    end
                    
                    default: ; 
                endcase
            end

            if (state == WAIT_DONE &&((header_r[2:0] == CMD_PT && enc_done) ||(header_r[2:0] == CMD_CT && dec_done) || 
				(header_r[2:0] == CMD_CT && enc_done && header_r[5:3] !=  MODE_ECB && header_r[5:3] !=  MODE_CBC))) begin

                output_packet[151:144] <= header_r;
                output_packet[143:128] <= seq_id_r;

                case (header_r[5:3])
                    MODE_ECB:
                        output_packet[127:0] <= (header_r[2:0] == CMD_CT) ? dec_out : enc_out;

                    MODE_CTR:
                        output_packet[127:0] <= enc_out ^ saved_input;

                    MODE_CBC: begin
                        if (header_r[2:0] == CMD_PT) begin 
                            output_packet[127:0] <= enc_out;
                            feedback <= enc_out;
                        end else begin 
                            output_packet[127:0] <= dec_out ^ (new_stream_delayed ? counter : last_ct);
                            last_ct <= saved_input;
                        end
                    end

                    MODE_CFB: begin
                        output_packet[127:0] <= enc_out ^ saved_input;
                        if (header_r[2:0] == CMD_PT) 
                             feedback <= enc_out ^ saved_input; 
                        else 
                             feedback <= saved_input;           
                    end

                    MODE_OFB: begin
                        feedback <= enc_out;
                        output_packet[127:0] <= enc_out ^ saved_input;
                    end
                endcase
            end
        end
    end

endmodule