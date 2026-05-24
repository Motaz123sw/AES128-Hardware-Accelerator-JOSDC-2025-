module aes_fsm(
    input  wire        rst,
    input  wire        clk,
    input  wire        start,               // enable FSM (connected to Key Done)
    input  wire        input_fifo_empty,    // HIGH = input FIFO empty
    input  wire        output_fifo_full,    // HIGH = output FIFO full

    input  wire [127:0] round_keys [0:10],
    input  wire [151:0] input_packet,       // [151:144] header, [143:128] seq_id, [127:0] payload

    output reg  [151:0] output_packet,
    output reg          valid,
    output wire         rst_ififo,
    output wire         rst_ofifo,
    output reg          en_ififo,
    output reg          en_ofifo
);

    //---------------------------------------
    // FIFO resets
    //---------------------------------------
    assign rst_ififo = rst;
    assign rst_ofifo = rst;

    //---------------------------------------
    // Internal registers
    //---------------------------------------
    reg [7:0]   header_r;
    reg [15:0]  seq_id_r;
    reg [127:0] payload_r;

    //---------------------------------------
    // AES pipeline outputs and done signals
    //---------------------------------------
    wire [127:0] enc_out;
    wire [127:0] dec_out;
    wire enc_done;
    wire dec_done;

    //---------------------------------------
    // Pipeline start signals (controlled)
    //---------------------------------------
    reg enc_start, dec_start;

    //---------------------------------------
    // AES pipelines
    //---------------------------------------
    aes128_encrypt_pipeline encrypt_pipe (
        .clk(clk),
        .rst(rst),
        .start(enc_start),
        .block_in(payload_r), // Now stable when start is asserted
        .round_keys(round_keys),
        .done(enc_done),
        .cipher_text(enc_out)
    );

    aes128_decrypt_pipeline decrypt_pipe (
        .clk(clk),
        .rst(rst),
        .start(dec_start),
        .block_in(payload_r),
        .round_keys(round_keys),
        .done(dec_done),
        .plain_text(dec_out)
    );

    //---------------------------------------
    // FSM states
    //---------------------------------------
    typedef enum logic [2:0] {
        IDLE       = 3'd0,
        READ       = 3'd1,
		  READ_WAIT  = 3'd2,
        START_OP   = 3'd3,
        WAIT_DONE  = 3'd4, // NEW: Wait for pipeline & Latch Data
        WRITE_FIFO = 3'd5  // NEW: Write stable data to FIFO
    } state_t;

    state_t state, next_state;

    //---------------------------------------
    // State register
    //---------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    //---------------------------------------
    // Next-state logic
    //---------------------------------------
    always @(*) begin
        // defaults
        next_state = state;
        en_ififo   = 0;
        en_ofifo   = 0;
        valid      = 0;
        enc_start  = 0;
        dec_start  = 0;

        case (state)
            //---------------------------------
            IDLE: begin
                if (start && !input_fifo_empty && !output_fifo_full)
                    next_state = READ;
            end

            //---------------------------------
            READ: begin
                if (!output_fifo_full) begin
                    en_ififo = 1;       // Pop FIFO
                    // Data is latched on the transition out of this state
                    next_state = READ_WAIT; 
                end else begin
                    next_state = IDLE;
                end
            end
				
				READ_WAIT:begin
				    next_state = START_OP; 
				end
            //---------------------------------
            START_OP: begin
                // Data in payload_r is now stable. Pulse the pipeline.
                if (header_r == 8'd2)begin
                    enc_start = 1;
						  next_state = WAIT_DONE;
                end else if (header_r == 8'd3)begin
                    dec_start = 1;
						  next_state = WAIT_DONE;
					 end else begin
						  next_state = IDLE; 
					 end
            end

            //---------------------------------
            WAIT_DONE: begin
                // Wait for pipeline to finish.
                // The output_packet register will capture the result in this state.
                if ((header_r == 8'd2 && enc_done) || (header_r == 8'd3 && dec_done)) begin
                    next_state = WRITE_FIFO;
                end else begin
                    next_state = WAIT_DONE;
                end
            end

            //---------------------------------
            WRITE_FIFO: begin
                // Now output_packet is stable. Check Flow Control and Write.
                if (!output_fifo_full) begin
                    en_ofifo = 1;
                    valid    = 1;
                    next_state = IDLE;
                end else begin
                    // Backpressure: Stay here until FIFO has space
                    next_state = WRITE_FIFO;
                end
            end
        endcase
    end

    //---------------------------------------
    // Latch input packet on READ
    //---------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            payload_r <= 128'h0;
            header_r  <= 8'h0;
            seq_id_r  <= 16'h0;
        end else if (state == READ_WAIT) begin
            // Capture data coming from FIFO
            payload_r <= input_packet[127:0];
            seq_id_r  <= input_packet[143:128];
            header_r  <= input_packet[151:144];
        end
    end

    //---------------------------------------
    // Build output packet
    //---------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_packet <= 152'h0;
        end else if (state == WAIT_DONE) begin
            // Capture the result as soon as the pipeline is done
            if ((header_r == 8'd2 && enc_done) || (header_r == 8'd3 && dec_done)) begin
                output_packet[151:144] <= header_r;
                output_packet[143:128] <= seq_id_r;
                output_packet[127:0]   <= (header_r == 8'd2) ? enc_out : dec_out;
            end
        end
    end

endmodule