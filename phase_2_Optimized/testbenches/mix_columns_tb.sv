`timescale 1ns/1ps

module mix_columns_tb;

    // --- Inputs and Outputs for the DUT ---
    logic [7:0] in_state[3:0][3:0];
    logic [7:0] out_state[3:0][3:0];

    // --- Expected Result ---
    logic [7:0] expected_state[3:0][3:0];

    // --- Instantiate the Device Under Test (DUT) ---
    mix_columns dut (
        .in_state(in_state),
        .out_state(out_state)
    );

    // --- Test Logic ---
    initial begin
        // --- Declarations moved to the top for Verilog compatibility ---
        logic error_found;
        integer i, j;

        $display("---------------------------------");
        $display("[%0t] Starting MixColumns Testbench...", $time);

        // 1. Define the FIPS-197 (Appendix B) input test vector
        //    This is the state *after* the ShiftRows step
		     
   
   
   
        in_state[0] = '{8'hd4, 8'he0, 8'hb8, 8'h1e};
        in_state[1] = '{8'hbf, 8'hb4, 8'h41, 8'h27};
        in_state[2] = '{8'h5d, 8'h52, 8'h11, 8'h98};
        in_state[3] = '{8'h30, 8'hae, 8'hf1, 8'he5};

        // 2. Define the FIPS-197 expected output vector
        //    This is the correct result for the input above
        expected_state[0] = '{8'h04, 8'he0, 8'h48, 8'h28};
        expected_state[1] = '{8'h66, 8'hcb, 8'hf8, 8'h06};
        expected_state[2] = '{8'h81, 8'h19, 8'hd3, 8'h26};
        expected_state[3] = '{8'he5, 8'h9a, 8'h7a, 8'h4c};

        // 3. Wait for the combinational logic to propagate
        #10;

        // 4. Check the results
        error_found = 1'b0;

        $display("[%0t] Checking results...", $time);
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                
                    $display("ERROR at state[%0d][%0d]:", i, j);
                    $display("  Expected: 0x%h", expected_state[i][j]);
                    $display("  Got:      0x%h", out_state[i][j]);
						  if (out_state[i][j] !== expected_state[i][j]) begin
                    error_found = 1'b1;
                end
            end
        end

        // 5. Report final status
        if (error_found) begin
            $display("[%0t] --- TEST FAILED ---", $time);
        end else begin
            $display("[%0t] --- TEST PASSED! ---", $time);
        end
        $display("---------------------------------");

        $finish;
    end

    // Optional: Monitor for any changes (good for debugging)
    initial begin
        $monitor("[%0t] in_state[0][0]=0x%h -> out_state[0][0]=0x%h",
                 $time, in_state[0][0], out_state[0][0]);
    end

endmodule