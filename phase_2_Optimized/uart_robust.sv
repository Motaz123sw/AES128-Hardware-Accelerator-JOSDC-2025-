// =============================================================================
// DROP-IN REPLACEMENT: Parameterized Robust UART 
// =============================================================================
module uart_robust #(
    parameter CLK_FREQ   = 50_000_000, // System Clock Frequency
    parameter BAUD_RATE  = 921_600,    // Target Baud Rate
    parameter OVERSAMPLE = 16          // Oversampling factor (typically 8 or 16)
)(
    input  logic clk,
    input  logic reset_n,
    input  logic uart_rxd,
    output logic uart_txd,
    output logic rx_valid,
    output logic [7:0] rx_byte,
    input  logic tx_valid,
    input  logic [7:0] tx_byte,
    output logic tx_ready
);

    // -------------------------------------------------------------------------
    // BAUD TICK GENERATOR (Fractional Phase Accumulator)
    // -------------------------------------------------------------------------
    // This provides exact average timing even for high baud rates like 921.6k
    localparam longint ACC_WIDTH = 32;
    localparam longint INC = ((longint'(BAUD_RATE) * OVERSAMPLE) << ACC_WIDTH) / CLK_FREQ;
    
    logic [ACC_WIDTH-1:0] acc;
    logic tick;
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            acc <= 0;
            tick <= 0;
        end else begin
            {tick, acc} <= acc + INC[ACC_WIDTH-1:0];
        end
    end

    // -------------------------------------------------------------------------
    // INTERNAL SIGNALS & CONSTANTS
    // -------------------------------------------------------------------------
    logic tx_busy;
    assign tx_ready = ~tx_busy; 
    
    // Calculate counter widths based on OVERSAMPLE
    localparam OVERSAMPLE_WIDTH = $clog2(OVERSAMPLE);
    localparam MID_SAMPLE       = (OVERSAMPLE / 2) - 1;
    localparam MAX_SAMPLE       = OVERSAMPLE - 1;

    // -------------------------------------------------------------------------
    // RECEIVER (Robust Mid-Bit Sampling)
    // -------------------------------------------------------------------------
    logic [3:0] rx_state; 
    logic [OVERSAMPLE_WIDTH-1:0] rx_tick_ctr;
    logic rx_sync;
    
    // Sync input to avoid metastability
    always_ff @(posedge clk) rx_sync <= uart_rxd;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_state <= 0; rx_tick_ctr <= 0; rx_valid <= 0; rx_byte <= 0;
        end else begin
            rx_valid <= 0;
            if (tick) begin
                if (rx_state == 0) begin // IDLE
                    if (rx_sync == 0) begin 
                        rx_state <= 1; 
                        rx_tick_ctr <= 0; 
                    end
                end else begin
                    rx_tick_ctr <= rx_tick_ctr + 1;
                    if (rx_tick_ctr == MID_SAMPLE[OVERSAMPLE_WIDTH-1:0]) begin // Middle of bit
                        case (rx_state)
                            1: begin // Start Bit
                                if (rx_sync == 1) rx_state <= 0; // Glitch? Go back
                                else rx_state <= 2;
                            end
                            10: begin // Stop Bit
                                rx_state <= 0;
                                rx_valid <= 1; // Valid Data!
                            end
                            default: begin // Data Bits
                                rx_byte <= {rx_sync, rx_byte[7:1]};
                                rx_state <= rx_state + 1;
                            end
                        endcase
                    end
                    if (rx_tick_ctr == MAX_SAMPLE[OVERSAMPLE_WIDTH-1:0]) begin
                        rx_tick_ctr <= 0;
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // TRANSMITTER
    // -------------------------------------------------------------------------
    logic [3:0] tx_bit_idx; 
    logic [OVERSAMPLE_WIDTH-1:0] tx_tick_ctr;
    logic [8:0] tx_shifter;
    logic tx_active;

    assign tx_busy = tx_active;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            uart_txd <= 1; tx_active <= 0; tx_tick_ctr <= 0; tx_bit_idx <= 0; tx_shifter <= 0;
        end else begin
            if (tx_valid && !tx_active) begin
                tx_active <= 1;
                tx_shifter <= {1'b1, tx_byte}; // Stop + Data
                uart_txd <= 0; // Start Bit
                tx_tick_ctr <= 0;
                tx_bit_idx <= 0;
            end else if (tx_active && tick) begin
                tx_tick_ctr <= tx_tick_ctr + 1;
                if (tx_tick_ctr == MAX_SAMPLE[OVERSAMPLE_WIDTH-1:0]) begin
                    tx_tick_ctr <= 0;
                    if (tx_bit_idx == 9) begin
                        tx_active <= 0; uart_txd <= 1;
                    end else begin
                        uart_txd <= tx_shifter[0];
                        tx_shifter <= tx_shifter >> 1;
                        tx_bit_idx <= tx_bit_idx + 1;
                    end
                end
            end
        end
    end
endmodule