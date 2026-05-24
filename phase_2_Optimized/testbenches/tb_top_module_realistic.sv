`timescale 1ns / 1ps

module tb_top_module_realistic;

    // =========================================================================
    // CONFIGURATION
    // =========================================================================
    localparam CLK_FREQ      = 50_000_000;    
    localparam BAUD_RATE     = 57600;         
    localparam CLK_PERIOD    = 20;            
    localparam BIT_PERIOD    = 1_000_000_000 / BAUD_RATE; 

    // Packet Constants
    localparam CMD_KEY  = 3'd1;
    localparam CMD_PT   = 3'd2;
    localparam CMD_IV   = 3'd4;
    localparam MODE_ECB = 3'd0;
    localparam STREAM_0 = 2'd0;

    // =========================================================================
    // SIGNALS
    // =========================================================================
    reg  clk;
    reg  rst_n;
    reg  uart_rxd;  
    wire uart_txd;  

    // =========================================================================
    // DUT INSTANTIATION
    // =========================================================================
    top_module_phase_2 dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd)
    );

    // =========================================================================
    // ---------------------- THE SPY SECTION ----------------------------------
    // =========================================================================
    
    // 1. SPY ON CONTROL UNIT (The Source)
	 
	 wire [127:0] spy_ivcounter_iva = dut.u_counter_unit.iv_data_A;
	 wire [127:0] spy_ivcounter_ivb = dut.u_counter_unit.iv_data_B;
	 

	 wire [2:0]spy_cu_state = dut.u_control_unit.state; // Is CU signalling Core 0?  
	 wire [1:0]spy_cu_selected_core = dut.u_control_unit.selected_core; 
	 wire [151:0]spy_cu_packet = dut.u_control_unit.pkt;
	 wire [151:0]spy_cu_rx_data = dut.u_control_unit.rx_data;
	 wire [1:0]spy_cu_active_stream_0 = dut.u_control_unit.active_stream_c0; 
	 wire [1:0]spy_cu_active_stream_1 = dut.u_control_unit.active_stream_c1;   
	 wire spy_cu_core0_active = dut.u_control_unit.c0_is_active;   
	 wire spy_cu_core1_active = dut.u_control_unit.c1_is_active;   


    // 2. SPY ON CORE 0 FIFO (The Mailbox)
    // We look inside: top -> core_0 -> aes_in_fifo
	     wire [127:0] spy_fifo_counter_0 = dut.u_core_0.u_aes_fsm.counter;
	     wire [127:0] spy_fifo_payload_0 = dut.u_core_0.u_aes_fsm.payload_r;
		  wire  spy_fifo_newstream_0 = dut.u_core_0.u_aes_fsm.is_new_stream_now;
		  wire  spy_fifo_newstream_reg_0 = dut.u_core_0.u_aes_fsm.new_stream;




    wire spy_fifo_empty_0 = dut.u_core_0.u_aes_in_fifo.empty;
    wire spy_fifo_full_0  = dut.u_core_0.u_aes_in_fifo.full;
    wire spy_fifo_wen_0   = dut.u_core_0.u_aes_in_fifo.w_en;    // Is data being written?
    wire spy_fifo_ren_0  = dut.u_core_0.u_aes_in_fifo.r_en; 
	 wire spy_fifo_valid_aesfsm_0   = dut.u_core_0.u_aes_fsm.valid; 
	     wire [127:0] spy_fifo_counter_1 = dut.u_core_1.u_aes_fsm.counter;
		  wire [127:0] spy_fifo_payload_1 = dut.u_core_1.u_aes_fsm.payload_r;
		  wire  spy_fifo_newstream_1 = dut.u_core_1.u_aes_fsm.is_new_stream_now;
		  wire  spy_fifo_newstream_reg_1 = dut.u_core_1.u_aes_fsm.new_stream;



	 // Is FSM reading data?
    wire spy_fifo_empty_1 = dut.u_core_1.u_aes_in_fifo.empty;
    wire spy_fifo_full_1  = dut.u_core_1.u_aes_in_fifo.full;
    wire spy_fifo_wen_1   = dut.u_core_1.u_aes_in_fifo.w_en;    // Is data being written?
    wire spy_fifo_ren_1  = dut.u_core_1.u_aes_in_fifo.r_en; 
	 wire spy_fifo_valid_aesfsm_1   = dut.u_core_1.u_aes_fsm.valid;
    // 3. SPY ON CORE 0 FSM (The Processor)
    // We look inside: top -> core_0 -> aes_fsm
    // Note: If your state variable is named 'state' instead of 'current_state', change it here.
    wire [2:0] spy_fsm_state_0 = dut.u_core_0.u_aes_fsm.state; 
    wire [2:0] spy_fsm_state_1 = dut.u_core_1.u_aes_fsm.state; 
    
    // 4. SPY ON CORE 0 OUTPUT (The Result)
    wire spy_core_out_valid_0 = dut.u_core_0.valid_core;       // Is Core trying to push to Arbiter?
	 wire spy_core_out_keydone_0 = dut.u_core_0.key_expan_done; 
	 wire spy_core_out_keystart_0 = dut.u_core_0.key_expan_done;
	 wire spy_core_full_core_0 = dut.u_core_0.full_core; 
    wire spy_core_out_valid_1 = dut.u_core_1.valid_core;       // Is Core trying to push to Arbiter?
	 wire spy_core_out_keydone_1 = dut.u_core_1.key_expan_done; 
	 wire spy_core_out_keystart_1 = dut.u_core_1.key_expan_done;
	 wire spy_core_full_core_1 = dut.u_core_1.full_core; 
 	 // Is Core trying to push to Arbiter?
	 // Is Core trying to push to Arbiter?

    wire spy_read_done_0      = dut.u_core_1.read_done_core; 
    wire spy_read_done_1      = dut.u_core_1.read_done_core; 	 // Did Arbiter accept it?

    // --- LOGGING BLOCK ---
    // This will print to the console whenever these critical signals change
    always @(spy_fifo_wen_0 or spy_fsm_state_0 or spy_fifo_empty_0) begin
        if (rst_n) begin
            $display("[SPY %10t]  FIFO_Write: %b | FIFO_Empty: %b | FSM_State: %d", 
                     $time,  spy_fifo_wen_0, spy_fifo_empty_0, spy_fsm_state_0);
        end
    end

    // =========================================================================
    // CLOCK GENERATION
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // UART TASKS
    // =========================================================================
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            uart_rxd = 0; // Start Bit
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd = data[i];
                #(BIT_PERIOD);
            end
            uart_rxd = 1; // Stop Bit
            #(BIT_PERIOD);
        end
    endtask

    task send_packet(input [7:0] header, input [15:0] seq, input [127:0] payload);
        integer i;
        reg [7:0] current_byte;
        begin
            $display("[TB] Sending Packet - Header: %h, Seq: %d", header, seq);
            for (i = 0; i < 16; i = i + 1) begin
                current_byte = payload[8*i +: 8]; 
                uart_send_byte(current_byte);
            end
            uart_send_byte(seq[7:0]);   
            uart_send_byte(seq[15:8]);  
            uart_send_byte(header);
            
            #(BIT_PERIOD * 5); 
        end
    endtask

    // =========================================================================
    // MAIN STIMULUS
    // =========================================================================
    initial begin
        $dumpfile("debug_waveform.vcd");
        $dumpvars(0, tb_top_module_realistic);

        $display("---------------------------------------------------");
        $display(" STARTING SIMULATION WITH CORE SPY");
        $display("---------------------------------------------------");
        rst_n = 0;
        uart_rxd = 1; 
        
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);
        
        $display("[TB] Reset Released...");
        #(CLK_PERIOD * 100);

        // 1. KEY
        send_packet({STREAM_0, 3'b001, CMD_KEY}, 16'd0, 128'h2b7e151628aed2a6abf7158809cf4f3c);
        #(BIT_PERIOD * 50); 

        // 2. IV
        send_packet({STREAM_0, 3'b001, CMD_IV}, 16'd1, 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff);

        // 3. PT 1 (Seq 2)
        send_packet({2'b00,3'b001, 3'b010}, 16'd2, 128'h6bc1bee22e409f96e93d7e117393172a);
		  #(BIT_PERIOD * 50); 
        
		  send_packet({2'b00, 3'b001, 3'b010}, 16'd3, 128'hae2d8a571e03ac9c9eb76fac45af8e51);
        #(BIT_PERIOD * 50);
        // 4. PT 2 (Seq 3)
        send_packet({2'b00, 3'b001, 3'b010}, 16'd4, 128'h30c81c46a35ce411e5fbc1191a0a52ef);
		  #(BIT_PERIOD * 50); 
		  
		  send_packet({2'b00, 3'b001, 3'b010}, 16'd5, 128'hf69f2445df4f9b17ad2b417be66c371);
		  #(BIT_PERIOD * 50);
        
        $display("[TB] All packets sent. Waiting for processing...");
        
        // Wait long enough for the last packet to (fail to) appear
        #(BIT_PERIOD * 19 * 10*3); 
        
        $display("[TB] Simulation Finished.");
        $stop;
    end

// =========================================================================
    // UART MONITOR (BUFFERED)
    // =========================================================================
    reg [7:0] rx_byte;
    reg [151:0] collected_pkt; // 19 bytes * 8 bits = 152 bits
    integer bit_idx;
    integer byte_cnt;
     
    initial begin
        byte_cnt = 0;
        collected_pkt = 0;

        forever begin
            // 1. Wait for Start Bit
            @(negedge uart_txd);
            
            // 2. Align to center of start bit, then wait for first data bit
            #(BIT_PERIOD + (BIT_PERIOD / 2));
            
            // 3. Sample 8 bits
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                rx_byte[bit_idx] = uart_txd;
                #(BIT_PERIOD); // Wait for next bit
            end
            
            // 4. Store the byte into the buffer
            // We verify "Correct Endian": First byte received goes to [7:0] (LSB side)
            // Last byte received goes to [151:144] (MSB side)
            collected_pkt[(byte_cnt * 8) +: 8] = rx_byte;
            byte_cnt = byte_cnt + 1;

            // 5. Check if we have all 19 bytes
            if (byte_cnt == 19) begin
                $display("[TB MONITOR] Full 19-Byte Packet: %h at time %t", collected_pkt, $time);
                
                // Reset for the next packet
                byte_cnt = 0;
                collected_pkt = 0;
            end
        end
    end

endmodule