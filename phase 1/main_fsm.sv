module main_fsm (
    input  wire         clk,            // SYSTEM CLOCK (Fast, e.g., 50MHz)
    input  wire         rst,            // SYSTEM RESET (Synchronized)

    // Interface to RX Bridge (Async FIFO Reading)
    input  wire [151:0] rx_data,        // Data from the RX Async FIFO
    input  wire         rx_empty,       // Is RX FIFO empty?
    output reg          rx_rd_en,       // Pop data from RX FIFO

    // Interface to TX Bridge (Async FIFO Writing)
    output reg  [151:0] tx_data,        // Data to the TX Async FIFO
    output reg          tx_wr_en,       // Push data to TX FIFO
    input  wire         tx_full,        // Is TX FIFO full?

    // Interface to Key Expansion (Direct - Same Clock!)
    output reg  [127:0] key_in,
    output reg          key_go,
    input  wire         key_done,

    // Interface to AES Processing (Input FIFO)
    output reg  [151:0] aes_in_data,
    output reg          aes_in_wr_en,
    input  wire         aes_in_full,    // Backpressure from AES FIFO

    // Interface from AES Processing (Output FIFO)
    input  wire [151:0] aes_out_data,
    input  wire         aes_out_empty,
    output reg          aes_out_rd_en,

    // Global Control
    output reg          sys_enable,      // Enables AES FSM
    output reg          soft_rst         // Global Soft Reset
);

    //------------------------------------------------------------------
    // Definitions
    //------------------------------------------------------------------
    localparam [7:0] CMD_RESET = 8'h00;
    localparam [7:0] CMD_KEY   = 8'h01;
    localparam [7:0] CMD_PT    = 8'h02;
    localparam [7:0] CMD_CT    = 8'h03;
    localparam [7:0] CMD_STOP  = 8'h04;

    localparam [3:0] IDLE          = 4'd0,
                     READ_WAIT     = 4'd1, // NEW: Wait for FIFO RAM access
                     DECODE        = 4'd2,
                     KEY_START     = 4'd3,
                     KEY_WAIT      = 4'd4,
                     PUSH_TO_AES   = 4'd5,
                     CHECK_AES_OUT = 4'd6,
                     PUSH_TO_TX    = 4'd7,
                     DO_RESET      = 4'd8;

    reg [3:0] state, next_state;
    reg [151:0] captured_packet;
    reg aes_active; // Switch state

    assign sys_enable = aes_active;

    //------------------------------------------------------------------
    // State Register & Sequential Logic
    //------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            aes_active <= 1'b1; // Default Active
            captured_packet <= 0;
        end else begin
            state <= next_state;

            // Packet Capture Logic (FIXED)
            // We capture in READ_WAIT state, exactly 1 cycle after rx_rd_en was asserted in IDLE
            if (state == READ_WAIT) begin
                captured_packet <= rx_data;
            end

            // AES Switch Logic
            if (state == DECODE) begin
                if (captured_packet[151:144] == CMD_STOP)
                    aes_active <= 1'b0;
                else if (captured_packet[151:144] == CMD_KEY)
                    aes_active <= 1'b1;
                // Soft Reset also re-enables
            end else if (state == DO_RESET) begin
                aes_active <= 1'b1;
            end
        end
    end

    //------------------------------------------------------------------
    // Combinational Logic
    //------------------------------------------------------------------
    always @(*) begin
        // Defaults
        next_state    = state;
        rx_rd_en      = 0;
        tx_wr_en      = 0;
        tx_data       = 152'd0;
        aes_in_wr_en  = 0;
        aes_in_data   = 152'd0;
        aes_out_rd_en = 0;
        key_go        = 0;
        key_in        = 128'd0;
        soft_rst      = 0;

        case (state)
            //----------------------------------------------------------
            // 1. IDLE: Monitor RX Bridge and AES Output
            //----------------------------------------------------------
            IDLE: begin
                // Priority 1: New Data from UART RX
                if (!rx_empty) begin
                    rx_rd_en = 1; // Pop the packet
                    next_state = READ_WAIT; // Go to wait state, NOT Decode immediately
                end 
                // Priority 2: Processed Data from AES ready to send to TX
                else if (!aes_out_empty && !tx_full) begin
                    next_state = CHECK_AES_OUT;
                end
            end

            //----------------------------------------------------------
            // 1b. READ_WAIT: Allow FIFO latency
            //----------------------------------------------------------
            READ_WAIT: begin
                // One cycle delay to allow rx_data to become valid.
                // Data is latched in the 'always @(posedge clk)' block during this state.
                next_state = DECODE;
            end

            //----------------------------------------------------------
            // 2. DECODE
            //----------------------------------------------------------
            DECODE: begin
                case (captured_packet[151:144])
                    CMD_RESET: next_state = DO_RESET;
                    CMD_STOP:  next_state = IDLE; // Switch logic handled in always_ff
                    
                    CMD_KEY:   next_state = KEY_START;
                    
                    CMD_PT, CMD_CT: next_state = PUSH_TO_AES;

                    default:   next_state = IDLE; // Ignore junk
                endcase
            end

            //----------------------------------------------------------
            // 3. KEY HANDLING (Direct communication)
            //----------------------------------------------------------
            KEY_START: begin
                key_in = captured_packet[127:0];
                key_go = 1; // Pulse GO
                next_state = KEY_WAIT;
            end

            KEY_WAIT: begin
                // Wait for the 'done' signal (same clock domain!)
                if (key_done) begin
                    // Assuming AES needs to know a key update happened:
                    next_state = PUSH_TO_AES; 
                end
                // Else stay in KEY_WAIT
            end

            //----------------------------------------------------------
            // 4. DATA HANDLING (Push to AES Input FIFO)
            //----------------------------------------------------------
            PUSH_TO_AES: begin
                if (!aes_in_full) begin
                    aes_in_data  = captured_packet;
                    aes_in_wr_en = 1;
                    next_state   = IDLE;
                end
                // Else wait for space
            end

            //----------------------------------------------------------
            // 5. OUTPUT HANDLING (AES -> UART TX Bridge)
            //----------------------------------------------------------
            CHECK_AES_OUT: begin
                // Read from AES Output FIFO
                aes_out_rd_en = 1;
                next_state = PUSH_TO_TX;
            end

            PUSH_TO_TX: begin
                // Write to UART TX Async FIFO
                tx_data  = aes_out_data;
                tx_wr_en = 1;
                next_state = IDLE;
            end

            //----------------------------------------------------------
            // 6. RESET
            //----------------------------------------------------------
            DO_RESET: begin
                soft_rst = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule