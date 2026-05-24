`timescale 1ns/1ps

module tb_key_expansion_fsm;

    // --- Signals ---
    logic clk;
    logic rst;
    logic go;
    logic [127:0] key_in;
    logic done;
    logic [127:0] round_keys[0:10];

    // --- Timing Measurement Variables ---
    realtime t_start, t_end, t_diff;
    logic has_failed; 
    integer i;

    // --- Clock Generation ---
    // Period = 10ns (100 MHz)
    // You can change this to #2.5 (200MHz) etc., 
    // but behavioral simulation will usually pass regardless of speed.
    localparam CLK_PERIOD = 10; 
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- DUT Instantiation ---
    key_expansion_fsm dut (
        .clk        (clk),
        .rst        (rst),
        .go         (go),
        .key_in     (key_in),
        .done       (done),
        .round_keys (round_keys)
    );

    // --- Expected Keys (Golden Reference) ---
    localparam logic [127:0] expected_keys[0:10] = '{
        128'h2b7e151628aed2a6abf7158809cf4f3c,
        128'ha0fafe1788542cb123a339392a6c7605,
        128'hf2c295f27a96b9435935807a7359f67f,
        128'h3d80477d4716fe3e1e237e446d7a883b,
        128'hef44a541a8525b7fb671253bdb0bad00,
        128'hd4d1c6f87c839d87caf2b8bc11f915bc,
        128'h6d88a37a110b3efddbf98641ca0093fd,
        128'h4e54f70e5f5fc9f384a64fb24ea6dc4f,
        128'head27321b58dbad2312bf5607f8d292f,
        128'hac7766f319fadc2128d12941575c006e,
        128'hd014f9a8c9ee2589e13f0cc8b6630ca6
    };

    // --- Test Execution ---
    initial begin
        $display("--- Starting Testbench for key_expansion_fsm ---");

        // 1. Init
        rst = 1;
        go = 0;
        key_in = 0;
        has_failed = 0;

        // 2. Reset
        #(CLK_PERIOD*2);
        rst = 0;
        #(CLK_PERIOD);

        // 3. Start Timer & Operation
        $display("Applying Key...");
        key_in = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        
        // Sync with clock edge for clean timing
        @(posedge clk);
        t_start = $realtime; // <--- CAPTURE START TIME
        $display("[TIME REPORT] Start Time: %0t ps", t_start);
        
        go = 1;
        @(posedge clk); 
        go = 0;

        // 4. Wait for Done & Stop Timer
        wait (done == 1'b1);
        t_end = $realtime;   // <--- CAPTURE END TIME
        $display("[TIME REPORT] End Time:   %0t ps", t_end);

        // 5. Calculate Duration
        t_diff = t_end - t_start;
        $display("------------------------------------------------");
        $display("PERFORMANCE REPORT:");
        $display("Total Time Taken: %0t ps", t_diff);
        $display("Clock Period:     %0d ns", CLK_PERIOD);
        $display("Latency in Cycles: %0d cycles", t_diff / CLK_PERIOD);
        $display("------------------------------------------------");

        // 6. Verify Data (Wait a tiny bit for data to settle if needed)
        #1; 
        for (i = 0; i <= 10; i++) begin
            if (round_keys[i] !== expected_keys[i]) begin
                $display("!!! ERROR: Round %0d mismatch!", i);
                has_failed = 1;
            end
				$display(" %0h", expected_keys[i]);
				$display("! Round %0d match!", i);
        end

        if (has_failed) $display("\n--- TEST FAILED ---");
        else            $display("\n+++ TEST PASSED +++");

        $finish; 
    end

endmodule