`timescale 1ns/1ps

module tb_key_expansion_bit_level;

    // --- Signals to connect to the DUT ---
    logic [127:0] in_key;
    logic [127:0] round_keys[0:10];
    // *** FIX 1: 'has_failed' should be a single bit (logic), not 32 bits ***
	logic has_failed; 

    // --- Instantiate the Device Under Test (DUT) ---
    // *** FIX: Instantiate the correct word-level module ***
    key_expansion dut (
        .in_key     (in_key),
        .round_keys (round_keys)
    );

	 integer i ;
    // --- Expected Key Schedule (from FIPS-197, Appendix A.1) ---
    // This is the "golden" reference we check against.
    // Key: 0x2b7e151628aed2a6abf7158809cf4f3c
    localparam logic [127:0] expected_keys[0:10] = '{
        128'h2b7e151628aed2a6abf7158809cf4f3c, // Round 0 (Initial Key)
        128'ha0fafe1788542cb123a339392a6c7605, // Round 1
        128'hf2c295f27a96b9435935807a7359f67f, // Round 2
        128'h3d80477d4716fe3e1e237e446d7a883b, // Round 3
        128'hef44a541a8525b7fb671253bdb0bad00, // Round 4
        128'hd4d1c6f87c839d87caf2b8bc11f915bc, // Round 5
        128'h6d88a37a110b3efddbf98641ca0093fd, // Round 6
        128'h4e54f70e5f5fc9f384a64fb24ea6dc4f, // Round 7
        128'head27321b58dbad2312bf5607f8d292f, // Round 8
        128'hac7766f319fadc2128d12941575c006e, // Round 9
        128'hd014f9a8c9ee2589e13f0cc8b6630ca6  // Round 10
    };

    // --- Test Execution ---
    initial begin
        $display("--- Starting Testbench for key_expansion (Word-Level) ---");

        // 1. Set the input key
        in_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;

        // 2. Wait for the combinational logic to settle
        //    (A small delay is good practice)
        #100;

        // 3. Check the results
          has_failed = 1'b0;
			 
 $display("    EXPECTED: %h", expected_keys[0]);
                $display("    GOT:      %h", round_keys[0]);
        for ( i = 0; i <= 10; i++) begin
            // *** FIX 2: Compare i to i, not i to 10-i ***
				                // *** FIX 2: Display the correct expected key ***
                $display("    EXPECTED: %h", expected_keys[i]);
                $display("    GOT:      %h", round_keys[i]);
                has_failed = 1'b1;
            if (round_keys[i] !== expected_keys[i]) begin
                $display("!!! ERROR: Round %0d mismatch!", i);

            end else begin
				$display("!!! ERROR: Round %0d match!", i);
				end
        end

        // 4. Report final status
        if (has_failed) begin
            $display("\n--- TEST FAILED ---");
        end else begin
            $display("\n+++ TEST PASSED! All 11 round keys are correct. +++");
        end

        $finish; // End the simulation
    end

endmodule