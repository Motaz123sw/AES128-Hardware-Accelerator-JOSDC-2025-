module control_unit(
    input  wire           clk,
    input  wire           rst,

    // RX FIFO
    input  wire [151:0]   rx_data,
    input  wire           rx_empty,
    output reg            rx_rd_en,

    // Core interface
    input  wire           new_stream_at_core_0,
    input  wire           new_stream_at_core_1,
    input  wire           core_0_full,
    input  wire           core_1_full,

    output reg [151:0]    packet_out,
    output reg            valid_to_core_0,
    output reg            valid_to_core_1,

    // Counter / IV
    output reg            core_0_counter_select,
    output reg            core_1_counter_select,
    output reg [127:0]    counter_A_IV,
    output reg [127:0]    counter_B_IV,
    output reg            load_IV_A,
    output reg            load_IV_B,
    output reg            core_0_is_ctr,
    output reg            core_1_is_ctr,
	 output reg            pkt_is_eos_0,
	 output reg            pkt_is_eos_1
);

    // ============================================================
    // PARAMETERS
    // ============================================================

    localparam CMD_EOS = 3'd0;
    localparam CMD_KEY = 3'd1;
	 localparam CMD_PT = 3'd2;
	 localparam CMD_CT = 3'd3;
    localparam CMD_IV  = 3'd4;
	 
    localparam CTRL_ECB = 3'd0;
    localparam CTRL_CTR = 3'd1;

    localparam S_IDLE      = 3'd0;
	 localparam S_READ_WAIT = 3'd1;
    localparam S_READ      = 3'd2;
    localparam S_DECODE    = 3'd3;
    localparam S_WAIT_CORE = 3'd4;
    localparam S_ROUTE     = 3'd5;

    // ============================================================
    // STATE + STORAGE
    // ============================================================

    reg [2:0] state;

    reg [151:0] pkt;
    reg [1:0]   pkt_stream;
    reg         pkt_is_key, pkt_is_iv, pkt_is_eos ,pkt_is_ctr;

    reg [1:0]   selected_core; // 1 = core0, 2 = core1

    reg c0_is_active, c1_is_active;
    reg [1:0] active_stream_c0, active_stream_c1;

    reg wait_c0, wait_c1;
    reg [127:0] held_iv_c0, held_iv_c1;
    reg [1:0] pending_stream_c0, pending_stream_c1;
    reg pending_is_ctr_c0, pending_is_ctr_c1;

    // ============================================================
    // FSM
    // ============================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;

            rx_rd_en <= 0;
            valid_to_core_0 <= 0;
            valid_to_core_1 <= 0;

            c0_is_active <= 0;
            c1_is_active <= 0;

            wait_c0 <= 0;
            wait_c1 <= 0;

            load_IV_A <= 0;
            load_IV_B <= 0;
        end
        else begin

            // defaults
            rx_rd_en <= 0;
            valid_to_core_0 <= 0;
            valid_to_core_1 <= 0;
            load_IV_A <= 0;
            load_IV_B <= 0;
				pkt_is_eos_0 <=0;
				pkt_is_eos_1 <=0;

            case (state)

            // ====================================================
            // IDLE
            // ====================================================
            S_IDLE: begin
                if (!rx_empty) begin
                    rx_rd_en <= 1;      // request FIFO read
                    state <= S_READ_WAIT;    // wait 1 cycle
                end
            end
				
				S_READ_WAIT: begin
					state <= S_READ;
				end

            // ====================================================
            // READ (FIFO latency alignment)
            // ====================================================
            S_READ: begin
                pkt <= rx_data;      // data valid now
                state <= S_DECODE;
            end

            // ====================================================
            // DECODE
            // ====================================================
            S_DECODE: begin

                pkt_stream <= pkt[151:150];
                pkt_is_key <= (pkt[146:144] == CMD_KEY);
                pkt_is_iv  <= (pkt[146:144] == CMD_IV);
                pkt_is_eos <= (pkt[146:144] == CMD_EOS);
                pkt_is_ctr <= (pkt[149:147] == CTRL_CTR);

                // KEY allocation
                if (pkt[146:144] == CMD_KEY) begin
                    if (!c0_is_active || (c0_is_active && active_stream_c0 == pkt[151:150]))
                        selected_core <= 2'd1;
                    else if (!c1_is_active || (c1_is_active && active_stream_c1 == pkt[151:150]))
                        selected_core <= 2'd2;
                    else
                        selected_core <= 2'd0;
								
                end else if (c0_is_active && active_stream_c0 == pkt[151:150])
                        selected_core <= 2'd1;
                    else if (c1_is_active && active_stream_c1 == pkt[151:150])
                        selected_core <= 2'd2;
                    else
                        selected_core <= 2'd0;

                state <= S_WAIT_CORE;
            end

            // ====================================================
            // WAIT FOR CORE READY
            // ====================================================
            S_WAIT_CORE: begin
                if (selected_core == 2'd1 && !core_0_full)
                    state <= S_ROUTE;
                else if (selected_core == 2'd2 && !core_1_full)
                    state <= S_ROUTE;
					 else state <=S_IDLE;
            end

            // ====================================================
            // ROUTE (1-cycle pulse)
            // ====================================================
            S_ROUTE: begin

                packet_out <= pkt;

                if (selected_core == 2'd1) begin
						if(pkt[146:144] == CMD_KEY || pkt[146:144] == CMD_PT || pkt[146:144] == CMD_CT) begin
                    valid_to_core_0 <= 1;
						end else begin
						valid_to_core_0 <= 0;
						end

                    // KEY
                    if (pkt_is_key) begin
                        c0_is_active <= 1;
                        active_stream_c0 <= pkt_stream;
                        pending_stream_c0 <= pkt_stream;
                        pending_is_ctr_c0 <= pkt_is_ctr;
                    end

                    // IV
                    if (pkt_is_iv) begin
                        held_iv_c0 <= pkt[127:0];
                        wait_c0 <= 1;
                    end

                    // EOS
                    if (pkt_is_eos) begin
                        c0_is_active <= 0;
								pkt_is_eos_0 <= 1;
                    end
                end

                else if (selected_core == 2'd2) begin
					 
						if(pkt[146:144] == CMD_KEY || pkt[146:144] == CMD_PT || pkt[146:144] == CMD_CT) begin
							valid_to_core_1 <= 1;
						end else begin
							valid_to_core_1 <= 0;
						end

                    if (pkt_is_key) begin
                        c1_is_active <= 1;
                        active_stream_c1 <= pkt_stream;
                        pending_stream_c1 <= pkt_stream;
                        pending_is_ctr_c1 <= pkt_is_ctr;
                    end

                    if (pkt_is_iv) begin
                        held_iv_c1 <= pkt[127:0];
                        wait_c1 <= 1;
                    end

                    if (pkt_is_eos) begin
                        c1_is_active <= 0;
								pkt_is_eos_1 <= 1;
                    end
                end

                state <= S_IDLE;
            end

            endcase

            // ====================================================
            // IV HANDSHAKE (independent of FSM)
            // ====================================================

            if (wait_c0 && new_stream_at_core_0) begin
                core_0_counter_select <= (pending_stream_c0 == 1);
                core_0_is_ctr <= pending_is_ctr_c0;

                if (pending_stream_c0 == 0) begin
                    counter_A_IV <= held_iv_c0;
                    load_IV_A <= 1;
                end else begin
                    counter_B_IV <= held_iv_c0;
                    load_IV_B <= 1;
                end

                wait_c0 <= 0;
            end

            if (wait_c1 && new_stream_at_core_1) begin
                core_1_counter_select <= (pending_stream_c1 == 1);
                core_1_is_ctr <= pending_is_ctr_c1;

                if (pending_stream_c1 == 0) begin
                    counter_A_IV <= held_iv_c1;
                    load_IV_A <= 1;
                end else begin
                    counter_B_IV <= held_iv_c1;
                    load_IV_B <= 1;
                end

                wait_c1 <= 0;
            end

        end
    end

endmodule
