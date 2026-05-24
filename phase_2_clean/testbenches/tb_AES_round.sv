// Testbench for the AES_round module
module tb_AES_round;

    // Inputs to the DUT
    logic [127:0] tb_input;
    logic [127:0] tb_key;
    
    // Output from the DUT
    wire  [127:0] tb_output;

    // Expected "golden" output
    logic [127:0] golden_output;

    // Instantiate the Device Under Test (DUT)
    AES_round dut (
        .Plain_text(tb_input),
        .Round_key(tb_key),
        .cipher_text(tb_output)
    );

    // Initial block for stimulus and checking
    initial begin
        $display("Starting AES_round testbench...");

        // Assign test vectors from FIPS-197 (AES-128 example)
        // This is the *input* to Round 1 (Plaintext XOR RoundKey 0)
        tb_input      = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        
        // This is the Round 1 Key
        tb_key        = 128'ha0fafe1788542cb123a339392a6c7605;
        
        // This is the expected *output* after Round 1 
        golden_output = 128'ha49c7ff2689f352b6b5bea43026a5049;
		  //fullround 128'ha49c7ff2689f352b6b5bea43026a5049
		  //sbox 128'hd42711aee0bf98f1b8b45de51e415230
		  //shift 128'hd4bf5d30e0b452aeb84111f11e2798e5
		  //mix 128'h046681e5e0cb199a48f8d37a2806264c
        // Wait for combinational logic to settle
        #30; 

        // Check the result
        if (tb_output === golden_output) begin
            $display("***********************************");
            $display("PASS: Output matches golden vector.");
            $display("***********************************");
        end else begin
            $display("***********************************");
            $display("FAIL: Output does not match golden vector.");
            $display("  Input:    %h", tb_input);
            $display("  Key:      %h", tb_key);
            $display("  Expected: %h", golden_output);
            $display("  Got:      %h", tb_output);
            $display("***********************************");
            $display("(Note: This is expected if using stub modules)");
        end

        // Finish the simulation
        $finish;
    end

endmodule