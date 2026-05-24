`timescale 1ns/1ps

module tb_aes_accelerator_system_new;

    //----------------------------------------------------------------
    // 1. Signals & Variables
    //----------------------------------------------------------------
    logic clk;
    logic rst_btn;
    logic uart_rxd;
    wire  uart_txd;

    // Timing Parameters (Must match DUT defaults)
    localparam CLOCK_FREQ_MHZ  = 50;
    localparam CLOCK_PERIOD_NS = 1000 / CLOCK_FREQ_MHZ; // 20ns
    localparam CLKS_PER_BIT    = 868; // Standard 57600 baud at 50MHz
    localparam BIT_PERIOD_NS   = CLKS_PER_BIT * CLOCK_PERIOD_NS; // 17360 ns

    // NIST Test Vectors (FIPS-197)
    localparam [127:0] NIST_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_PT  = 128'h6bc1bee22e409f96e93d7e117393172a;
    localparam [127:0] NIST_CT  = 128'h3ad77bb40d7a3660a89ecaf32466ef97;

    // Packet Headers
    localparam [7:0] CMD_RESET = 8'h00;
    localparam [7:0] CMD_KEY   = 8'h01;
    localparam [7:0] CMD_PT    = 8'h02;
    localparam [7:0] CMD_CT    = 8'h03;

    //----------------------------------------------------------------
    // 2. DUT Instantiation
    //----------------------------------------------------------------
    aes_accelerator_top dut (
        .clk(clk),
        .rst_btn(rst_btn),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd)
    );

    //----------------------------------------------------------------
    // 3. Clock Generation (50 MHz)
    //----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD_NS/2) clk = ~clk;
    end

    //----------------------------------------------------------------
    // 4. UART TX Tasks (Simulate Host Sending to FPGA)
    //----------------------------------------------------------------
    
    // Task: Send a single byte via UART (8N1)
    task uart_send_byte(input [7:0] byte_in);
        integer i;
        begin
            // Start Bit (Low)
            uart_rxd = 0;
            #(BIT_PERIOD_NS);
            
            // Data Bits (LSB First)
            for (i=0; i<8; i++) begin
                uart_rxd = byte_in[i];
                #(BIT_PERIOD_NS);
            end
            
            // Stop Bit (High)
            uart_rxd = 1;
            #(BIT_PERIOD_NS);
        end
    endtask

    // Task: Send full 19-byte packet
    // Packet Structure in Verilog: {Header, Seq, Data}
    // UART Order: LSB First (Data[7:0] -> ... -> Header[7:0])
    task send_packet(input [7:0] header, input [15:0] seq, input [127:0] data);
        logic [151:0] full_pkt;
        integer i;
        begin
            // Pack the 152 bits
            full_pkt = {header, seq, data};
            
            // Send 19 bytes, starting from LSB (Byte 0)
            // This ensures Byte 0 lands in the LSB of the FPGA's flattened vector
            for (i=0; i<19; i++) begin
                uart_send_byte(full_pkt[i*8 +: 8]);
            end
            
            // Small inter-packet delay
            #(BIT_PERIOD_NS * 5);
        end
    endtask

    //----------------------------------------------------------------
    // 5. UART RX Monitor (Simulate Host Receiving from FPGA)
    //----------------------------------------------------------------
    logic [7:0]   rx_byte_buf;
    logic [151:0] rx_pkt_asm;
    integer       rx_byte_idx = 0;

    initial begin
        // Init Receive Buffer
        rx_byte_idx = 0;
        rx_pkt_asm = 0;

        forever begin
            // 1. Wait for Start Bit (Falling Edge of TXD)
            @(negedge uart_txd);
            
            // 2. Verify it's a valid start bit (sample in middle)
            #(BIT_PERIOD_NS/2);
            if (uart_txd == 0) begin
                // Move to middle of first data bit
                #(BIT_PERIOD_NS);
                
                // 3. Sample 8 Data Bits
                for (int i=0; i<8; i++) begin
                    rx_byte_buf[i] = uart_txd;
                    #(BIT_PERIOD_NS);
                end
                
                // 4. Store Byte (LSB fill)
                // The FPGA sends LSB first, so we fill from the bottom up
                rx_pkt_asm[rx_byte_idx*8 +: 8] = rx_byte_buf;
                rx_byte_idx++;

                // 5. Check Packet Completion
                if (rx_byte_idx == 19) begin
                    $display("[TB @ %0t] <--- RECEIVED PACKET via UART: Header=0x%h | Seq=0x%h | Data=0x%h", 
                             $time, rx_pkt_asm[151:144], rx_pkt_asm[143:128], rx_pkt_asm[127:0]);
                    
                    // Reset for next packet
                    rx_byte_idx = 0;
                    rx_pkt_asm = 0;
                end
                
                // Wait out the Stop bit (to ensure we don't re-trigger immediately)
                // (Already at middle of last data bit, wait 1 bit period for stop bit middle)
                // #(BIT_PERIOD_NS); 
            end
        end
    end

    //----------------------------------------------------------------
    // 6. Main Test Sequence
    //----------------------------------------------------------------
    initial begin
        $display("=== AES Accelerator System Testbench (UART Mode) ===");
        $display("Baud Rate Period: %0d ns", BIT_PERIOD_NS);

        // --- Initialization ---
        rst_btn = 1;
        uart_rxd = 1; // Idle state for UART is High
        
        // --- Hard Reset ---
        #1000;
        rst_btn = 0;
        #1000;

        // NOTE: UART simulation takes significant time. 
        // 1 Packet ~ 3.3ms. 

        // --- Step 1: Reset Packet ---
        $display("[TB @ %0t] Sending RESET Packet (CMD 0x00)...", $time);
        send_packet(CMD_RESET, 16'h0000, 128'h0);
        
        // Gap
        #(BIT_PERIOD_NS * 10);

        // --- Step 2: Plain Text Packet (Should Queue) ---
        $display("[TB @ %0t] Sending Plaintext Packet 1 (Queued)...", $time);
        send_packet(CMD_PT, 16'h0001, NIST_PT);
		  $display("[TB @ %0t] Sending Plaintext Packet 2 (Queued)...", $time);
        send_packet(CMD_PT, 16'h0002, 128'hae2d8a571e03ac9c9eb76fac45af8e51);
		  $display("[TB @ %0t] Sending Plaintext Packet 3 (Queued)...", $time);
        send_packet(CMD_PT, 16'h0003, 128'h30c81c46a35ce411e5fbc1191a0a52ef);

        // --- Step 3: Key Packet (Unlocks System) ---
        $display("[TB @ %0t] Sending Key Packet (CMD 0x01)...", $time);
        send_packet(CMD_KEY, 16'hFFFF, NIST_KEY);
		  $display("[TB @ %0t] Sending Plaintext Packet 4 (Immediate)...", $time);
        send_packet(CMD_PT, 16'h0004, 128'hf69f2445df4f9b17ad2b417be66c3710);

        // Wait for processing. Key Expansion is fast, but UART transmission of result is slow.
        // We need to wait enough time for the PT result to come back.
        // 19 bytes * 10 bits * 17360ns = ~3.3ms
        $display("[TB] Waiting for Packet 1 Response...");
        #(4000000); // Wait 4ms

        // --- Step 4: Cipher Text Packet (Immediate) ---
        $display("[TB @ %0t] Sending Ciphertext Packet 5 (Immediate)...", $time);
        send_packet(CMD_CT, 16'h0005, 128'h3ad77bb40d7a3660a89ecaf32466ef97);
		  $display("[TB @ %0t] Sending Ciphertext Packet 7 (Immediate)...", $time);
		  send_packet(CMD_CT, 16'h0007, 128'hf5d3d58503b9699de785895a96fdbaaf);
		  $display("[TB @ %0t] Sending Ciphertext Packet 8 (Immediate)...", $time);
		  send_packet(CMD_CT, 16'h0008, 128'h43b1cd7f598ece23881b00e3ed030688);
		  $display("[TB @ %0t] Sending Ciphertext Packet 9 (Immediate)...", $time);
		  send_packet(CMD_CT, 16'h0009, 128'h7b0c785e27e8ad3f8223207104725dd4);

        // Wait for result
        $display("[TB] Waiting for Packet 2 Response...");
        #(40000000); // Wait 4ms

        $display("=== Test Complete ===");
        $finish;
    end

endmodule