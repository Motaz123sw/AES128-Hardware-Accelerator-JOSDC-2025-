module top_module_phase_2 (
    input  wire         clk,        // 50 MHz System Clock
    input  wire         rst_n,      // Active Low Reset

    // UART Physical Interface
    input  wire         uart_rxd,
    output wire         uart_txd
);

    // ============================================================
    // INTERNAL SIGNALS & WIRES
    // ============================================================
    
    // Reset generation
    wire rst;
    assign rst = ~rst_n;

    // ------------------------------------------------------------
    // UART Interface Signals
    // ------------------------------------------------------------
    wire [151:0] uart_rx_data;
    wire         uart_rx_empty;
    wire         uart_rx_rd_en;

    wire [151:0] uart_tx_data;
    wire         uart_tx_full;
    wire         uart_tx_wr_en;
    wire         uart_tx_active;

    // ------------------------------------------------------------
    // Control Unit -> Core Handshake Signals
    // ------------------------------------------------------------
    wire [151:0] cu_packet_out;
    wire         cu_valid_core0;
    wire         cu_valid_core1;
    
    wire         core0_new_stream_ack;
    wire         core1_new_stream_ack;
    wire         core0_full;
    wire         core1_full;

    // ------------------------------------------------------------
    // Control Unit -> Counter Unit Signals
    // ------------------------------------------------------------
    wire         cu_core0_cnt_sel;
    wire         cu_core1_cnt_sel;
    wire         cu_core0_is_ctr;
    wire         cu_core1_is_ctr;
    
    // UPDATED: Wires are now 128-bit wide
    wire [127:0] cu_cnt_A_iv;   
    wire [127:0] cu_cnt_B_iv;   
    wire         cu_load_A;
    wire         cu_load_B;

    // Counter Unit -> Core Signals
    wire [127:0] cnt_iv_core0;
    wire [127:0] cnt_iv_core1;

    // ------------------------------------------------------------
    // Core -> Arbiter Signals
    // ------------------------------------------------------------
    wire [151:0] core0_out_packet;
    wire         core0_out_valid;
    wire         core0_read_done; 

    wire [151:0] core1_out_packet;
    wire         core1_out_valid;
    wire         core1_read_done; 

    wire         core0_ififo_en; 
    wire         core1_ififo_en; 
	 
	 
	 
	 wire is_eos_wire0;
	 wire is_eos_wire1;


    // ============================================================
    // 1. UART TOP (PHY + FIFOs)
    // ============================================================
    top_uart u_uart_top (
        .clk(clk),
        .reset_n(rst_n),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd),
        .rx_fifo_read_en(uart_rx_rd_en),
        .rx_fifo_data_out(uart_rx_data),
        .rx_fifo_empty(uart_rx_empty),
        .tx_fifo_write_en(uart_tx_wr_en),
        .tx_fifo_data_in(uart_tx_data),
        .tx_fifo_full(uart_tx_full),
        .tx_active(uart_tx_active)
    );

    // ============================================================
    // 2. CONTROL UNIT (Brain)
    // ============================================================
    control_unit u_control_unit (
        .clk(clk),
        .rst(rst),

        // RX FIFO Interface
        .rx_data(uart_rx_data),
        .rx_empty(uart_rx_empty),
        .rx_rd_en(uart_rx_rd_en),

        // Core Interface
        .new_stream_at_core_0(core0_new_stream_ack),
        .new_stream_at_core_1(core1_new_stream_ack),
        .core_0_full(core0_full),
        .core_1_full(core1_full),
        
        .packet_out(cu_packet_out),
        .valid_to_core_0(cu_valid_core0),
        .valid_to_core_1(cu_valid_core1),

        // Counter Unit Interface
        .core_0_counter_select(cu_core0_cnt_sel),
        .core_1_counter_select(cu_core1_cnt_sel),
        
        // UPDATED: 128-bit connections
        .counter_A_IV(cu_cnt_A_iv), 
        .counter_B_IV(cu_cnt_B_iv), 
        
        .load_IV_A(cu_load_A),
        .load_IV_B(cu_load_B),
        
        // Mode Outputs
        .core_0_is_ctr(cu_core0_is_ctr),
        .core_1_is_ctr(cu_core1_is_ctr),
		  .pkt_is_eos_0(is_eos_wire0),
		  .pkt_is_eos_1(is_eos_wire1)
    );

    // ============================================================
    // 3. COUNTER / IV UNIT
    // ============================================================
    counter_iv_unit u_counter_unit (
        .clk(clk),
        .rst(rst),

        .load_iv_A(cu_load_A),
        .load_iv_B(cu_load_B),
        
        // UPDATED: Direct 128-bit connection (No padding needed)
        .iv_data_A(cu_cnt_A_iv), 
        .iv_data_B(cu_cnt_B_iv),

        .core_0_select(cu_core0_cnt_sel),
        .core_1_select(cu_core1_cnt_sel),
        
        .core_0_is_ctr(cu_core0_is_ctr),
        .core_1_is_ctr(cu_core1_is_ctr),

        .core_0_pop(core0_ififo_en),
        .core_1_pop(core1_ififo_en),
        
        .core_0_eos(1'b0), 
        .core_1_eos(1'b0),

        .iv_out_core_0(cnt_iv_core0),
        .iv_out_core_1(cnt_iv_core1)
    );

    // ============================================================
    // 4. AES CORES
    // ============================================================
    
    // --- CORE 0 ---
    core u_core_0 (
        .clk(clk),
        .rst(rst),
        .input_packet_core(cu_packet_out),
        .ififo_en_core(cu_valid_core0), 
        .full_core(core0_full),        
        .counter_core(cnt_iv_core0),
        .output_packet_core(core0_out_packet),
        .valid_core(core0_out_valid),
        .read_done_core(core0_read_done), 
        .new_stream_core(core0_new_stream_ack),
        .ififo_en(core0_ififo_en), 
        .ofull_core(uart_tx_full),
		  .is_eos_core(is_eos_wire0)
		    
    );

    // --- CORE 1 ---
    core u_core_1 (
        .clk(clk),
        .rst(rst),
        .input_packet_core(cu_packet_out),
        .ififo_en_core(cu_valid_core1),
        .full_core(core1_full),
        .counter_core(cnt_iv_core1),
        .output_packet_core(core1_out_packet),
        .valid_core(core1_out_valid),
        .read_done_core(core1_read_done),
        .new_stream_core(core1_new_stream_ack),
        .ififo_en(core1_ififo_en),
        .ofull_core(uart_tx_full),
		  .is_eos_core(is_eos_wire1)
    );

    // ============================================================
    // 5. ROUND ROBIN ARBITER (Output Mux)
    // ============================================================
    round_robin #(
        .DATA_WIDTH(152) 
    ) u_arbiter (
        .clk(clk),
        .reset(rst),
        .data_in0(core0_out_packet),
        .valid0(core0_out_valid),
        .data_in1(core1_out_packet),
        .valid1(core1_out_valid),
        .fifo_full(uart_tx_full),
        .readDone0(core0_read_done),
        .readDone1(core1_read_done),
        .dataOut(uart_tx_data),
        .fifoEnable(uart_tx_wr_en),
        .fifoReset()
    );

endmodule