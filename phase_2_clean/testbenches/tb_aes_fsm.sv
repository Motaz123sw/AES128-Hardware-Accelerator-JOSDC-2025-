`timescale 1ns/1ps

module tb_aes_fsm;

    //----------------------------------------------------------------
    // 1. Signal Declarations
    //----------------------------------------------------------------
    logic clk;
    logic rst;
    
    //-------------------------------------
    // Testbench <-> Input FIFO Signals
    //-------------------------------------
    logic         tb_write_en;
    logic [151:0] tb_write_data;
    logic         tb_input_fifo_full;

    //-------------------------------------
    // Input FIFO <-> DUT Signals
    //-------------------------------------
    logic [151:0] dut_input_packet;      // Connects FIFO rdata -> DUT input_packet
    logic         dut_input_fifo_empty;  // Connects FIFO empty -> DUT input_fifo_empty
    logic         dut_en_ififo;          // Connects DUT en_ififo -> FIFO r_en
    logic         dut_rst_ififo;         // From DUT (unused in this specific FIFO IP, using global rst)

    //-------------------------------------
    // DUT <-> Output FIFO Signals
    //-------------------------------------
    logic [151:0] dut_output_packet;     // Connects DUT output_packet -> FIFO wdata
    logic         dut_output_fifo_full;  // Connects FIFO full -> DUT output_fifo_full
    logic         dut_en_ofifo;          // Connects DUT en_ofifo -> FIFO w_en
    logic         dut_rst_ofifo;         // From DUT

    //-------------------------------------
    // Output FIFO <-> Testbench Signals
    //-------------------------------------
    logic         tb_read_en;
    logic [151:0] tb_read_data;
    logic         tb_output_fifo_empty;

    //-------------------------------------
    // Key Expansion Signals
    //-------------------------------------
    logic         key_go;
    logic         key_done;
    logic [127:0] master_key;
    logic [127:0] round_keys [0:10];
    logic         dut_valid; // DUT valid signal (debug use)

    // NIST Test Vectors
    localparam [127:0] NIST_KEY       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_PT        = 128'h6bc1bee22e409f96e93d7e117393172a;
    localparam [151:0] NIST_CT_PACKET = 152'h0200013ad77bb40d7a3660a89ecaf32466ef97;

    //----------------------------------------------------------------
    // 2. Clock Generation
    //----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    //----------------------------------------------------------------
    // 3. Module Instantiations
    //----------------------------------------------------------------

    // 3a. Key Expansion FSM
    key_expansion_fsm u_key_gen (
        .clk        (clk),
        .rst        (rst),
        .go         (key_go),
        .key_in     (master_key),
        .done       (key_done),
        .round_keys (round_keys)
    );

    // 3b. Input FIFO
    // TB writes to it, DUT reads from it.
    async_fifo #(
        .WIDTH(152), .DEPTH(16)
    ) u_input_fifo (
        .wclk  (clk),
        .wrst  (rst),
        .w_en  (tb_write_en),
        .wdata (tb_write_data),
        .full  (tb_input_fifo_full),

        .rclk  (clk),
        .rrst  (rst),
        .r_en  (dut_en_ififo),       // Driven by DUT
        .rdata (dut_input_packet),   // Drives DUT
        .empty (dut_input_fifo_empty)// Drives DUT
    );

    // 3c. AES FSM (The DUT)
    aes_fsm dut (
        .clk               (clk),
        .rst               (rst),
        .start             (key_done),         
        
        // Input Interface (Connected to Input FIFO)
        .input_fifo_empty  (dut_input_fifo_empty),
        .input_packet      (dut_input_packet),
        .en_ififo          (dut_en_ififo),
        .rst_ififo         (dut_rst_ififo),

        // Output Interface (Connected to Output FIFO)
        .output_fifo_full  (dut_output_fifo_full),
        .output_packet     (dut_output_packet),
        .en_ofifo          (dut_en_ofifo),
        .rst_ofifo         (dut_rst_ofifo),
        .valid             (dut_valid), // Debug signal

        .round_keys        (round_keys)
    );

    // 3d. Output FIFO
    // DUT writes to it, TB reads from it.
    async_fifo #(
        .WIDTH(152), .DEPTH(16)
    ) u_output_fifo (
        .wclk  (clk),
        .wrst  (rst),
        .w_en  (dut_en_ofifo),       // Driven by DUT
        .wdata (dut_output_packet),  // Driven by DUT
        .full  (dut_output_fifo_full),// Drives DUT

        .rclk  (clk),
        .rrst  (rst),
        .r_en  (tb_read_en),
        .rdata (tb_read_data),
        .empty (tb_output_fifo_empty)
    );

    //----------------------------------------------------------------
    // 4. Main Test Sequence
    //----------------------------------------------------------------
    initial begin
        $display("=== AES FSM Testbench with Integrated FIFOs ===");
        
        // --- Initialize ---
        rst = 1;
        key_go = 0;
        master_key = 0;
        
        // TB Flow Control Init
        tb_write_en = 0;
        tb_write_data = 0;
        tb_read_en = 0;

        // --- Reset ---
        #100;
        rst = 0;
        #20;
        
        // --- Step 1: Run Key Expansion ---
        $display("[Time %0t] Starting Key Expansion...", $time);
        master_key = NIST_KEY;
        
        @(posedge clk);
        key_go = 1;
        @(posedge clk);
        key_go = 0;

        wait(key_done == 1);
        $display("[Time %0t] Key Gen Done. System Ready.", $time);
        repeat(5) @(posedge clk);

        // --- Step 2: Inject Packet into Input FIFO ---
        $display("[Time %0t] Writing NIST Vector to Input FIFO...", $time);
        
        if (!tb_input_fifo_full) begin
            // Header 0x02 (Encrypt), Seq 0x0001, Payload NIST_PT
            tb_write_data = {8'h02, 16'h0001, NIST_PT};
            tb_write_en = 1;
            @(posedge clk);
            tb_write_en = 0;
        end else begin
            $display("Error: Input FIFO is full!");
            $finish;
        end
        
        $display("[Time %0t] Packet Written. Waiting for FSM processing...", $time);

        // --- Step 3: Wait for Result in Output FIFO ---
        // Monitor the Output FIFO Empty flag. When it goes low, data is ready.
        
        // Safety timeout in case FSM hangs
        fork
            begin
                wait(tb_output_fifo_empty == 0);
            end
            begin
                #2000; // Timeout after 2000ns
                if (tb_output_fifo_empty) begin
                    $display("[FAILURE] Timeout waiting for Output FIFO data.");
                    $finish;
                end
            end
        join

        $display("[Time %0t] Data detected in Output FIFO!", $time);

        // --- Step 4: Read from Output FIFO ---
        @(posedge clk);
        tb_read_en = 1; // Request Pop
        @(posedge clk);
        tb_read_en = 0; 
        
        // IMPORTANT: Standard FIFO (non-FWFT) latency means data appears 
        // 1 cycle after read_en. The data is available on the bus NOW.
        // (Wait one more small delta or use the data captured at this posedge)
        #1; 

        // --- Step 5: Verify ---
        if (tb_read_data == NIST_CT_PACKET) begin
            $display("==================================================");
            $display(" [SUCCESS] Output FIFO Data matches NIST Ciphertext!");
            $display(" Expected: %h", NIST_CT_PACKET);
            $display(" Got:      %h", tb_read_data);
            $display("==================================================");
        end else begin
            $display("==================================================");
            $display(" [FAILURE] Output Mismatch.");
            $display(" Expected: %h", NIST_CT_PACKET);
            $display(" Got:      %h", tb_read_data);
            $display("==================================================");
        end

        #100;
        $finish;
    end

endmodule