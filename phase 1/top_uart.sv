// =============================================================================
// FILE: uart_full_design.sv
// =============================================================================

// -----------------------------------------------------------------------------
// MODULE: uart_byte_if (Physical Layer)
// -----------------------------------------------------------------------------
module uart_byte_if #(
    parameter CLKS_PER_BIT = 868
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
    // RX Logic
    enum logic [2:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state;
    logic [15:0] rx_clk_cnt;
    logic [2:0]  rx_bit_idx;
    logic [7:0]  rx_shift_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_state <= RX_IDLE; rx_valid <= 0; rx_byte <= 0; rx_clk_cnt <= 0; rx_bit_idx <= 0;
        end else begin
            rx_valid <= 0;
            case (rx_state)
                RX_IDLE: begin
                    rx_clk_cnt <= 0; rx_bit_idx <= 0;
                    if (uart_rxd == 1'b0) rx_state <= RX_START;
                end
                RX_START: begin
                    if (rx_clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        if (uart_rxd == 1'b0) begin rx_clk_cnt <= 0; rx_state <= RX_DATA; end
                        else rx_state <= RX_IDLE;
                    end else rx_clk_cnt <= rx_clk_cnt + 1;
                end
                RX_DATA: begin
                    if (rx_clk_cnt < CLKS_PER_BIT-1) rx_clk_cnt <= rx_clk_cnt + 1;
                    else begin
                        rx_clk_cnt <= 0; rx_shift_reg[rx_bit_idx] <= uart_rxd;
                        if (rx_bit_idx < 7) rx_bit_idx <= rx_bit_idx + 1; else rx_state <= RX_STOP;
                    end
                end
                RX_STOP: begin
                    if (rx_clk_cnt < CLKS_PER_BIT-1) rx_clk_cnt <= rx_clk_cnt + 1;
                    else begin rx_valid <= 1'b1; rx_byte <= rx_shift_reg; rx_state <= RX_IDLE; end
                end
            endcase
        end
    end

    // TX Logic
    enum logic [2:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state;
    logic [15:0] tx_clk_cnt;
    logic [2:0]  tx_bit_idx;
    logic [7:0]  tx_data_latch;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_state <= TX_IDLE; uart_txd <= 1'b1; tx_ready <= 1'b1; tx_clk_cnt <= 0; tx_bit_idx <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    uart_txd <= 1'b1; tx_ready <= 1'b1;
                    if (tx_valid) begin
                        tx_ready <= 1'b0; tx_data_latch <= tx_byte; tx_state <= TX_START; tx_clk_cnt <= 0;
                    end
                end
                TX_START: begin
                    uart_txd <= 1'b0;
                    if (tx_clk_cnt < CLKS_PER_BIT-1) tx_clk_cnt <= tx_clk_cnt + 1;
                    else begin tx_clk_cnt <= 0; tx_state <= TX_DATA; tx_bit_idx <= 0; end
                end
                TX_DATA: begin
                    uart_txd <= tx_data_latch[tx_bit_idx];
                    if (tx_clk_cnt < CLKS_PER_BIT-1) tx_clk_cnt <= tx_clk_cnt + 1;
                    else begin
                        tx_clk_cnt <= 0;
                        if (tx_bit_idx < 7) tx_bit_idx <= tx_bit_idx + 1; else tx_state <= TX_STOP;
                    end
                end
                TX_STOP: begin
                    uart_txd <= 1'b1;
                    if (tx_clk_cnt < CLKS_PER_BIT-1) tx_clk_cnt <= tx_clk_cnt + 1;
                    else begin tx_state <= TX_IDLE; tx_ready <= 1'b1; end
                end
            endcase
        end
    end
endmodule

// -----------------------------------------------------------------------------
// MODULE: uart_rx_fsm_pkt (Receiver - 19 Bytes Flat)
// -----------------------------------------------------------------------------
module uart_rx_fsm_pkt (
    input  logic clk, reset_n, rx_valid,
    input  logic [7:0] rx_byte,
    output logic packet_ready,
    output logic [7:0] packet_data [0:18]
);
    logic [4:0] byte_cnt;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            byte_cnt <= 0; packet_ready <= 0;
        end else begin
            packet_ready <= 0;
            if (rx_valid) begin
                packet_data[byte_cnt] <= rx_byte;
                if (byte_cnt == 18) begin packet_ready <= 1; byte_cnt <= 0; end
                else byte_cnt <= byte_cnt + 1;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// MODULE: uart_tx_fsm_pkt (Transmitter - 19 Bytes Flat)
// -----------------------------------------------------------------------------
module uart_tx_fsm_pkt (
    input  logic clk, reset_n, start_tx,
    input  logic [7:0] packet_data [0:18],
    output logic tx_valid,
    output logic [7:0] tx_byte,
    input  logic tx_ready,
    output logic tx_busy, tx_done
);
    typedef enum logic [2:0] {T_IDLE, T_SEND, T_WAIT_START, T_WAIT_DONE, T_FINISH} tstate_t;
    tstate_t state;
    logic [4:0] byte_cnt;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= T_IDLE; byte_cnt <= 0; tx_valid <= 0; tx_byte <= 0; tx_busy <= 0; tx_done <= 0;
        end else begin
            tx_valid <= 0; tx_done <= 0;
            case (state)
                T_IDLE: begin
                    tx_busy <= 0;
                    if (start_tx) begin byte_cnt <= 0; tx_busy <= 1; state <= T_SEND; end
                end
                T_SEND: begin
                    if (tx_ready) begin
                        tx_valid <= 1; tx_byte <= packet_data[byte_cnt];
                        byte_cnt <= byte_cnt + 1; state <= T_WAIT_START;
                    end
                end
                T_WAIT_START: state <= T_WAIT_DONE;
                T_WAIT_DONE: begin
                    if (tx_ready) begin
                        if (byte_cnt == 19) state <= T_FINISH; else state <= T_SEND;
                    end
                end
                T_FINISH: begin tx_busy <= 0; tx_done <= 1; state <= T_IDLE; end
                default: state <= T_IDLE;
            endcase
        end
    end
endmodule
// -----------------------------------------------------------------------------
// MODULE: top_uart (Top Level) with FIFOs
// -----------------------------------------------------------------------------
module top_uart (
    input  logic clk,
    input  logic reset_n,
    
    // Physical UART
    input  logic uart_rxd,
    output logic uart_txd,

    // ---------------------------------------------------------
    // RX FIFO INTERFACE (Read received packets here)
    // ---------------------------------------------------------
    input  logic         rx_fifo_read_en,
    output logic [151:0] rx_fifo_data_out,
    output logic         rx_fifo_empty,

    // ---------------------------------------------------------
    // TX FIFO INTERFACE (Write packets to send here)
    // ---------------------------------------------------------
    input  logic         tx_fifo_write_en,
    input  logic [151:0] tx_fifo_data_in,
    output logic         tx_fifo_full,
    output logic         tx_active // Status: 1 if UART is currently sending
);

    // Internal Signals
    logic rx_valid, tx_valid, tx_ready;
    logic [7:0] rx_byte, tx_byte;
    
    // FSM Signals
    logic pkt_rx_done;
    logic [7:0] rx_fsm_array [0:18];
    logic [7:0] tx_fsm_array [0:18];
    logic pkt_tx_start;
    logic tx_busy;
    
    // FIFO Glue Logic
    logic [151:0] rx_flattened_data;
    logic [151:0] tx_flattened_data;
    logic tx_fifo_read_internal;
    logic tx_fifo_empty_internal;
    logic rst_p; 

    // Assignments
    assign rst_p = ~reset_n; // FIFO uses Active High reset
    assign tx_active = tx_busy;

    // =========================================================================
    // 1. PHYSICAL UART
    // =========================================================================
    uart_byte_if #(.CLKS_PER_BIT(868)) U_IF (
        .clk(clk), .reset_n(reset_n),
        .uart_rxd(uart_rxd), .uart_txd(uart_txd),
        .rx_valid(rx_valid), .rx_byte(rx_byte),
        .tx_valid(tx_valid), .tx_byte(tx_byte), .tx_ready(tx_ready)
    );

    // =========================================================================
    // 2. RX PATH (UART -> FSM -> ARRAY -> VECTOR -> FIFO)
    // =========================================================================
    
    // A. RX FSM
    uart_rx_fsm_pkt U_RX (
        .clk(clk), .reset_n(reset_n), .rx_valid(rx_valid), .rx_byte(rx_byte),
        .packet_ready(pkt_rx_done), .packet_data(rx_fsm_array)
    );

    // B. Flatten Array (19 bytes) -> Vector (152 bits)
    always_comb begin
        for (int i=0; i<19; i++) begin
            rx_flattened_data[i*8 +: 8] = rx_fsm_array[i];
        end
    end

    // C. RX FIFO Instance
    async_fifo #(
        .WIDTH(152), .DEPTH(16)
    ) FIFO_RX (
        // Write Side (Internal FSM)
        .wclk(clk), .wrst(rst_p),
        .w_en(pkt_rx_done), .wdata(rx_flattened_data), .full(), 
        // Read Side (User Interface)
        .rclk(clk), .rrst(rst_p),
        .r_en(rx_fifo_read_en), .rdata(rx_fifo_data_out), .empty(rx_fifo_empty)
    );

    // =========================================================================
    // 3. TX PATH (FIFO -> VECTOR -> ARRAY -> FSM -> UART)
    // =========================================================================

    // A. TX FIFO Instance
    async_fifo #(
        .WIDTH(152), .DEPTH(16)
    ) FIFO_TX (
        // Write Side (User Interface)
        .wclk(clk), .wrst(rst_p),
        .w_en(tx_fifo_write_en), .wdata(tx_fifo_data_in), .full(tx_fifo_full),
        // Read Side (Internal Logic)
        .rclk(clk), .rrst(rst_p),
        .r_en(tx_fifo_read_internal), .rdata(tx_flattened_data), .empty(tx_fifo_empty_internal)
    );

    // B. TX CONTROL STATE MACHINE (Auto-Pop from FIFO)
    typedef enum logic [1:0] {S_CHECK, S_READ, S_START, S_WAIT} tx_ctrl_t;
    tx_ctrl_t tx_ctrl_state;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_ctrl_state <= S_CHECK; tx_fifo_read_internal <= 0; pkt_tx_start <= 0;
        end else begin
            tx_fifo_read_internal <= 0;
            pkt_tx_start <= 0;

            case (tx_ctrl_state)
                S_CHECK: begin
                    // If FIFO has data AND UART is free
                    if (!tx_fifo_empty_internal && !tx_busy) begin
                        tx_fifo_read_internal <= 1; // Pop
                        tx_ctrl_state <= S_READ;
                    end
                end
                S_READ: begin
                    // Wait for RAM access
                    tx_ctrl_state <= S_START;
                end
                S_START: begin
                    // Data valid now, trigger FSM
                    pkt_tx_start <= 1;
                    tx_ctrl_state <= S_WAIT;
                end
                S_WAIT: begin
                    // Wait for busy to assert so we don't re-trigger
                    if (tx_busy) tx_ctrl_state <= S_CHECK;
                end
            endcase
        end
    end

    // C. Unpack Vector (152 bits) -> Array (19 bytes)
    always_comb begin
        for (int i=0; i<19; i++) begin
            tx_fsm_array[i] = tx_flattened_data[i*8 +: 8];
        end
    end

    // D. TX FSM
    uart_tx_fsm_pkt U_TX (
        .clk(clk), .reset_n(reset_n), .start_tx(pkt_tx_start),
        .packet_data(tx_fsm_array), .tx_valid(tx_valid),
        .tx_byte(tx_byte), .tx_ready(tx_ready),
        .tx_busy(tx_busy), .tx_done()
    );

endmodule