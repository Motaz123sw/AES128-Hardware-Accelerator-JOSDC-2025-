`timescale 1ns/1ps

module tb_aes_accelerator_system;

    //----------------------------------------------------------------
    // 1. Signals & Variables
    //----------------------------------------------------------------
    logic clk;
    logic rst_btn;

    // Simulation Interface Signals
    logic [151:0] sim_in_data;
    logic         sim_in_w_en;
    wire          sim_in_full;

    wire [151:0]  sim_out_data;
    logic         sim_out_r_en;
    wire          sim_out_empty;

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
        // Input Feed
        .sim_in_data(sim_in_data),
        .sim_in_w_en(sim_in_w_en),
        .sim_in_full(sim_in_full),
        // Output Feed
        .sim_out_data(sim_out_data),
        .sim_out_r_en(sim_out_r_en),
        .sim_out_empty(sim_out_empty)
    );

    //----------------------------------------------------------------
    // 3. Clock Generation (50 MHz)
    //----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    //----------------------------------------------------------------
    // 4. Helper Tasks
    //----------------------------------------------------------------
    task send_packet(input [7:0] header, input [15:0] seq, input [127:0] data);
        begin
            // Wait for space in the FIFO
            wait(sim_in_full == 0);
            @(posedge clk);
            
            // Drive Data
            sim_in_data = {header, seq, data};
            sim_in_w_en = 1;
            
            @(posedge clk);
            sim_in_w_en = 0;
            // Small gap between packets
            repeat(2) @(posedge clk);
        end
    endtask

    //----------------------------------------------------------------
    // 5. Main Test Sequence
    //----------------------------------------------------------------
    initial begin
        $display("=== AES Accelerator System Testbench ===");
        
        // --- Initialization ---
        rst_btn = 1;
        sim_in_w_en = 0;
        sim_out_r_en = 0;
        
        // --- Hard Reset ---
        #100;
        rst_btn = 0;
        #50;

        // --- Step 1: Reset Packet ---
        $display("[TB @ %0t] Sending RESET Packet (CMD 0x00)", $time);
        send_packet(CMD_RESET, 16'h0000, 128'h0);
        
        // Wait for soft reset to propagate (Main FSM -> Reset Logic -> Key FSM cleared)
        #100; 

        // --- Step 2: Plain Text Packet (Should Queue) ---
        // Note: Key Expansion hasn't run yet, so Key Done is 0, AES FSM is disabled.
        $display("[TB @ %0t] Sending Plaintext Packet 1 (Queued)", $time);
        send_packet(CMD_PT, 16'h0001, NIST_PT);

        // --- Step 3: Cipher Text Packet (Should Queue) ---
        $display("[TB @ %0t] Sending Ciphertext Packet 1 (Queued)", $time);
        send_packet(CMD_CT, 16'h0002, NIST_CT);

        // --- Step 4: Key Packet (Unlocks System) ---
        $display("[TB @ %0t] Sending Key Packet (CMD 0x01)", $time);
        send_packet(CMD_KEY, 16'hFFFF, NIST_KEY);

        // At this point:
        // 1. Key Packet hits Main FSM.
        // 2. Main FSM triggers Key Expansion.
        // 3. Key Expansion finishes (approx 11-15 cycles).
        // 4. 'key_done' goes HIGH.
        // 5. AES FSM wakes up and processes the queued PT and CT packets.

        // Allow time for processing the queue
        #500; 

        // --- Step 5: Plain Text Packet (Immediate) ---
        // System is now active, this should stream through quickly.
        $display("[TB @ %0t] Sending Plaintext Packet 2 (Immediate)", $time);
        send_packet(CMD_PT, 16'h0003, 128'h11112222333344445555666677778888);

        // --- Step 6: Cipher Text Packet (Immediate) ---
        $display("[TB @ %0t] Sending Ciphertext Packet 2 (Immediate)", $time);
        send_packet(CMD_CT, 16'h0004, 128'hAAAABBBBCCCCDDDDEEEEFFFF00001111);

        // Wait for all outputs
        #2000000;
        $display("=== Test Complete ===");
        $finish;
    end

    reg sim_out_valid; // Delay register to track when data is actually ready

    always @(posedge clk) begin
        // 1. READ LOGIC
        // If FIFO is not empty, request a read.
        if (!sim_out_empty&& !sim_out_r_en) begin
            sim_out_r_en <= 1;
        end else begin
            sim_out_r_en <= 0;
        end

        // 2. LATENCY MANAGEMENT
        // For a standard FIFO, data is valid 1 cycle AFTER r_en is high.
        // We capture the state of r_en into a "valid" flag for the NEXT cycle.
        sim_out_valid <= sim_out_r_en;

        // 3. DISPLAY LOGIC
        // We check 'sim_out_valid' instead of 'sim_out_r_en'.
        // This ensures we print the data exactly when it arrives on the bus.
        if (sim_out_valid) begin
            $display("[TB @ %0t] <--- RECEIVED PACKET: Header=0x%h | Seq=0x%h | Data=0x%h", 
                $time,
                sim_out_data[151:144], 
                sim_out_data[143:128], 
                sim_out_data[127:0]
            );
        end
    end

endmodule