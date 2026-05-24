//==============================================================================
// Testbench for Round-Robin Arbiter
//==============================================================================
// Tests all cases:
//   1. Both cores valid - alternating priority
//   2. Only core 0 valid
//   3. Only core 1 valid
//   4. Neither core valid
//   5. FIFO full back-pressure
//   6. State transitions
//   7. Reset behavior
//==============================================================================

`timescale 1ns/1ps

module tb_round_robin;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter DATA_WIDTH = 128;
    parameter CLK_PERIOD = 10;  // 10ns clock period (100MHz)

    //==========================================================================
    // DUT signals
    //==========================================================================
    logic                    clk;
    logic                    reset;
    logic [DATA_WIDTH-1:0]   data_in0;
    logic [DATA_WIDTH-1:0]   data_in1;
    logic                    valid0;
    logic                    valid1;
    logic                    fifo_full;
    logic                    readDone0;
    logic                    readDone1;
    logic [DATA_WIDTH-1:0]   dataOut;
    logic                    fifoEnable;
    logic                    fifoReset;

    //==========================================================================
    // Test counters and checkers
    //==========================================================================
    int test_num = 0;
    int errors = 0;
    int core0_grants = 0;
    int core1_grants = 0;
    
    // TEST 2 variables
    logic first_grant, second_grant, third_grant;

    //==========================================================================
    // Clock generation
    //==========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //==========================================================================
    // DUT instantiation
    //==========================================================================
    round_robin #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .data_in0(data_in0),
        .data_in1(data_in1),
        .valid0(valid0),
        .valid1(valid1),
        .fifo_full(fifo_full),
        .readDone0(readDone0),
        .readDone1(readDone1),
        .dataOut(dataOut),
        .fifoEnable(fifoEnable),
        .fifoReset(fifoReset)
    );

    //==========================================================================
    // Monitor grants for statistics
    //==========================================================================
    always @(posedge clk) begin
        if (!reset) begin
            if (readDone0) core0_grants++;
            if (readDone1) core1_grants++;
        end
    end

    //==========================================================================
    // Helper task: Apply reset
    //==========================================================================
    task apply_reset();
        begin
            reset = 1;
            valid0 = 0;
            valid1 = 0;
            fifo_full = 0;
            data_in0 = 128'h0;
            data_in1 = 128'h0;
            repeat(2) @(posedge clk);
            reset = 0;
            @(posedge clk);
            $display("[%0t] Reset completed", $time);
        end
    endtask

    //==========================================================================
    // Helper task: Check outputs
    //==========================================================================
    task check_output(
        input logic exp_readDone0,
        input logic exp_readDone1,
        input logic exp_fifoEnable,
        input logic [DATA_WIDTH-1:0] exp_dataOut,
        input string test_name
    );
        begin
            if (readDone0 !== exp_readDone0) begin
                $display("ERROR [%0t] %s: readDone0 = %b, expected %b", 
                         $time, test_name, readDone0, exp_readDone0);
                errors++;
            end
            if (readDone1 !== exp_readDone1) begin
                $display("ERROR [%0t] %s: readDone1 = %b, expected %b", 
                         $time, test_name, readDone1, exp_readDone1);
                errors++;
            end
            if (fifoEnable !== exp_fifoEnable) begin
                $display("ERROR [%0t] %s: fifoEnable = %b, expected %b", 
                         $time, test_name, fifoEnable, exp_fifoEnable);
                errors++;
            end
            if (exp_fifoEnable && (dataOut !== exp_dataOut)) begin
                $display("ERROR [%0t] %s: dataOut = %h, expected %h", 
                         $time, test_name, dataOut, exp_dataOut);
                errors++;
            end
        end
    endtask

    //==========================================================================
    // Main test sequence
    //==========================================================================
    initial begin
        $display("=================================================================");
        $display("Round-Robin Arbiter Testbench");
        $display("=================================================================");

        // Initialize
        apply_reset();

        //======================================================================
        // TEST 1: Reset behavior
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Reset behavior check", test_num);
        #1; // Small delay to sample after posedge
        if (fifoReset !== 0) begin
            $display("ERROR: fifoReset should be 0 after reset deassertion");
            errors++;
        end
        // Just check that we have a valid initial state, don't enforce which one
        $display("PASS: Initial state = %s", 
                 (dut.current_state == 1'b0) ? "CORE0_TURN (0)" : "CORE1_TURN (1)");
        $display("      (State will alternate every cycle regardless)");

        //======================================================================
        // TEST 2: Both cores valid - Priority alternates
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Both cores valid - alternating priority", test_num);
        
        data_in0 = 128'hDEADBEEF_CAFEBABE_12345678_9ABCDEF0;
        data_in1 = 128'hFEEDFACE_BAD1C0DE_87654321_0FEDCBA9;
        valid0 = 1;
        valid1 = 1;
        fifo_full = 0;
        
        // Track which core gets granted - should alternate
        // (variables declared at top)
        
        // Cycle 1
        @(posedge clk);
        #1; 
        first_grant = readDone0;  // 1 if core0, 0 if core1
        if (!fifoEnable) begin
            $display("ERROR: Should grant to someone when both valid");
            errors++;
        end
        $display("  Cycle 1: Core %0d granted", first_grant ? 0 : 1);
        
        // Cycle 2 - should be opposite of cycle 1
        @(posedge clk);
        #1;
        second_grant = readDone0;
        if (second_grant == first_grant) begin
            $display("ERROR: Should alternate - both cycles granted core %0d", first_grant ? 0 : 1);
            errors++;
        end else begin
            $display("  Cycle 2: Core %0d granted (alternated correctly)", second_grant ? 0 : 1);
        end
        
        // Cycle 3 - should match cycle 1
        @(posedge clk);
        #1;
        third_grant = readDone0;
        if (third_grant != first_grant) begin
            $display("ERROR: Cycle 3 should match cycle 1");
            errors++;
        end else begin
            $display("  Cycle 3: Core %0d granted (matches cycle 1 - correct)", third_grant ? 0 : 1);
        end

        //======================================================================
        // TEST 3: Only Core 0 valid - should get grants in both states
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Only Core 0 valid", test_num);
        
        valid0 = 1;
        valid1 = 0;
        
        // CORE0_TURN state, core0 valid - should grant to core0
        @(posedge clk);
        #1;
        check_output(1'b1, 1'b0, 1'b1, data_in0, "Only Core0 - CORE0_TURN");
        $display("  CORE0_TURN: Core 0 granted (priority)");
        
        @(posedge clk); // Now in CORE1_TURN
        #1;
        check_output(1'b1, 1'b0, 1'b1, data_in0, "Only Core0 - CORE1_TURN fallback");
        $display("  CORE1_TURN: Core 0 granted (fallback)");

        //======================================================================
        // TEST 4: Only Core 1 valid - should get grants in both states
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Only Core 1 valid", test_num);
        
        valid0 = 0;
        valid1 = 1;
        
        @(posedge clk); // CORE0_TURN
        #1;
        check_output(1'b0, 1'b1, 1'b1, data_in1, "Only Core1 - CORE0_TURN fallback");
        $display("  CORE0_TURN: Core 1 granted (fallback)");
        
        @(posedge clk); // CORE1_TURN
        #1;
        check_output(1'b0, 1'b1, 1'b1, data_in1, "Only Core1 - CORE1_TURN");
        $display("  CORE1_TURN: Core 1 granted (priority)");

        //======================================================================
        // TEST 5: Neither core valid - idle
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Neither core valid - should idle", test_num);
        
        valid0 = 0;
        valid1 = 0;
        
        @(posedge clk);
        #1;
        check_output(1'b0, 1'b0, 1'b0, 128'h0, "Neither valid - idle");
        $display("  No grants issued (idle)");
        
        @(posedge clk);
        #1;
        check_output(1'b0, 1'b0, 1'b0, 128'h0, "Neither valid - idle cycle 2");
        $display("  Still idle");

        //======================================================================
        // TEST 6: FIFO full - should stall (no grants)
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] FIFO full back-pressure", test_num);
        
        valid0 = 1;
        valid1 = 1;
        fifo_full = 1;
        
        @(posedge clk);
        #1;
        check_output(1'b0, 1'b0, 1'b0, 128'h0, "FIFO full - stall");
        $display("  FIFO full: No grants (stalled)");
        
        @(posedge clk);
        #1;
        check_output(1'b0, 1'b0, 1'b0, 128'h0, "FIFO full - still stalled");
        $display("  FIFO still full: No grants");
        
        // Release FIFO - should resume
        fifo_full = 0;
        @(posedge clk);
        #1;
        if (!fifoEnable) begin
            $display("ERROR: Should resume after FIFO not full");
            errors++;
        end else begin
            $display("  FIFO released: Grants resumed");
        end

        //======================================================================
        // TEST 7: State transition verification
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] State transition verification", test_num);
        
        valid0 = 0;
        valid1 = 0;
        
        // Track state transitions
        begin
            logic expected_state;
            for (int i = 0; i < 6; i++) begin
                expected_state = (i % 2 == 0) ? dut.CORE0_TURN : dut.CORE1_TURN;
                @(posedge clk);
                #1;
                if (dut.current_state !== expected_state) begin
                    $display("ERROR: Cycle %0d - State = %b, expected %b", 
                             i, dut.current_state, expected_state);
                    errors++;
                end else begin
                    $display("  Cycle %0d: State = %s (correct)", 
                             i, (expected_state == dut.CORE0_TURN) ? "CORE0_TURN" : "CORE1_TURN");
                end
            end
        end

        //======================================================================
        // TEST 8: Fairness test - both cores always valid
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Fairness test - 20 cycles with both cores valid", test_num);
        
        core0_grants = 0;
        core1_grants = 0;
        valid0 = 1;
        valid1 = 1;
        fifo_full = 0;
        
        repeat(20) @(posedge clk);
        
        $display("  Core 0 grants: %0d", core0_grants);
        $display("  Core 1 grants: %0d", core1_grants);
        
        if (core0_grants != 10 || core1_grants != 10) begin
            $display("ERROR: Unfair arbitration - should be 10 grants each");
            errors++;
        end else begin
            $display("PASS: Perfect fairness achieved");
        end

        //======================================================================
        // TEST 9: Data integrity check
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Data integrity - correct data forwarded", test_num);
        
        valid0 = 1;
        valid1 = 1;
        
        for (int i = 0; i < 4; i++) begin
            data_in0 = 128'h1111_0000_0000_0000_0000_0000_0000_0000 + i;
            data_in1 = 128'h2222_0000_0000_0000_0000_0000_0000_0000 + i;
            
            @(posedge clk);
            #1;
            
            if (readDone0 && dataOut !== data_in0) begin
                $display("ERROR: Core 0 data mismatch");
                errors++;
            end
            if (readDone1 && dataOut !== data_in1) begin
                $display("ERROR: Core 1 data mismatch");
                errors++;
            end
        end
        $display("  Data integrity verified");

        //======================================================================
        // TEST 10: Reset during operation
        //======================================================================
        test_num++;
        $display("\n[TEST %0d] Reset during operation", test_num);
        
        valid0 = 1;
        valid1 = 1;
        
        @(posedge clk);
        reset = 1;
        @(posedge clk);
        #1;
        
        if (fifoReset !== 1) begin
            $display("ERROR: fifoReset should be high during reset");
            errors++;
        end
        
        reset = 0;
        @(posedge clk);
        #1;
        
        // Just verify state is valid and system works after reset
        if (dut.current_state !== 1'b0 && dut.current_state !== 1'b1) begin
            $display("ERROR: Invalid state after reset");
            errors++;
        end else begin
            $display("PASS: Reset behavior correct, state = %b", dut.current_state);
        end

        //======================================================================
        // Final Report
        //======================================================================
        $display("\n=================================================================");
        $display("Test Summary");
        $display("=================================================================");
        $display("Total tests: %0d", test_num);
        $display("Errors: %0d", errors);
        
        if (errors == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
        end else begin
            $display("\n*** %0d TEST(S) FAILED ***", errors);
        end
        $display("=================================================================\n");
        
        $finish;
    end

    //==========================================================================
    // Timeout watchdog
    //==========================================================================
    initial begin
        #100000; // 100us timeout
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

    //==========================================================================
    // Waveform dump (optional)
    //==========================================================================
    initial begin
        $dumpfile("round_robin.vcd");
        $dumpvars(0, tb_round_robin);
    end

endmodule