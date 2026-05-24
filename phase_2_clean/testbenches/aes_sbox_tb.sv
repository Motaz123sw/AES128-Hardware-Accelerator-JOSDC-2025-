// Testbench for the aes_sbox module (SubBytes operation)

module aes_sbox_tb;

    // -------------------------------------------------------------------------
    // 1. Signals for DUT (Device Under Test)
    // -------------------------------------------------------------------------
    // Input state register
    reg  [7:0] in_state_reg [3:0][3:0];
    // Output state wire
    wire [7:0] out_state_wire [3:0][3:0];
    
    // Expected output register for checking
    reg  [7:0] expected_out [3:0][3:0];
    
    // Iterators
    integer i, j;
    reg     [7:0] error_count = 8'h00;
    
    // -------------------------------------------------------------------------
    // 2. Instantiate the DUT
    // -------------------------------------------------------------------------
    canright_aes_sbox DUT (
        .in_state(in_state_reg),
        .out_state(out_state_wire)
    );

    // -------------------------------------------------------------------------
    // 3. Test Stimulus Generation
    // -------------------------------------------------------------------------
    initial begin
        // Initialize inputs to a known state
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                in_state_reg[i][j] = (i * 16) + j;
            end
        end

        // Wait for one timestep to allow the combinational logic to propagate
        #1; 
        
        // ---------------------------------------------------------------------
        // Set the expected output based on the S-box: 
        // We use the input (i*16 + j) as the index to get the expected output
        // The test case uses the first 16 consecutive S-box entries (0x00 to 0x0F, then 0x10 to 0x1F, etc.)
        // ---------------------------------------------------------------------
        
        // Input: 0x00 to 0x03
        expected_out[0][0] = 8'h63; expected_out[0][1] = 8'h7c; expected_out[0][2] = 8'h77; expected_out[0][3] = 8'h7b;
        // Input: 0x10 to 0x13
        expected_out[1][0] = 8'hca; expected_out[1][1] = 8'h82; expected_out[1][2] = 8'hc9; expected_out[1][3] = 8'h7d;
        // Input: 0x20 to 0x23
        expected_out[2][0] = 8'hb7; expected_out[2][1] = 8'hfd; expected_out[2][2] = 8'h93; expected_out[2][3] = 8'h26;
        // Input: 0x30 to 0x33
        expected_out[3][0] = 8'h04; expected_out[3][1] = 8'hc7; expected_out[3][2] = 8'h23; expected_out[3][3] = 8'hc3;
        
        // The remaining entries for this simple test:
        expected_out[0][0] = 8'h63; expected_out[0][1] = 8'h7c; expected_out[0][2] = 8'h77; expected_out[0][3] = 8'h7b;
        expected_out[0][0] = 8'h63; expected_out[0][1] = 8'h7c; expected_out[0][2] = 8'h77; expected_out[0][3] = 8'h7b;

        expected_out[0][0] = 8'h63; expected_out[0][1] = 8'h7c; expected_out[0][2] = 8'h77; expected_out[0][3] = 8'h7b;
        expected_out[0][4] = 8'hf2; expected_out[0][5] = 8'h6b; expected_out[0][6] = 8'h6f; expected_out[0][7] = 8'hc5;
        
        // Re-calculate the expected values for the 4x4 block corresponding to input 0x00...0x33
        // Row 0 (Inputs 0x00 to 0x03)
        expected_out[0][0] = 8'h63; expected_out[0][1] = 8'h7c; expected_out[0][2] = 8'h77; expected_out[0][3] = 8'h7b;
        // Row 1 (Inputs 0x10 to 0x13)
        expected_out[1][0] = 8'hca; expected_out[1][1] = 8'h82; expected_out[1][2] = 8'hc9; expected_out[1][3] = 8'h7d;
        // Row 2 (Inputs 0x20 to 0x23)
        expected_out[2][0] = 8'hb7; expected_out[2][1] = 8'hfd; expected_out[2][2] = 8'h93; expected_out[2][3] = 8'h26;
        // Row 3 (Inputs 0x30 to 0x33)
        expected_out[3][0] = 8'h04; expected_out[3][1] = 8'hc7; expected_out[3][2] = 8'h23; expected_out[3][3] = 8'hc3;
        
        // ---------------------------------------------------------------------
        // 4. Checking Logic and Reporting
        // ---------------------------------------------------------------------
        $display("-----------------------------------------------------");
        $display("Starting AES S-box Testbench");
        $display("Applying Input State (0x00, 0x01, 0x02, 0x03... to 0x33)");
        $display("Time=%0t", $time);
        $display("-----------------------------------------------------");

        // Check if the output matches the expected values
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                if (out_state_wire[i][j] !== expected_out[i][j]) begin
                    $display("ERROR at State[%0d][%0d]: Input=%h, Got=%h, Expected=%h", 
                              i, j, in_state_reg[i][j], out_state_wire[i][j], expected_out[i][j]);
                    error_count = error_count + 1;
                end
            end
        end

        if (error_count == 8'h00) begin
            $display("SUCCESS: All 16 S-box substitutions matched expected values.");
        end else begin
            $display("FAILURE: %0d errors found in substitution.", error_count);
        end
        $display("-----------------------------------------------------");
        
        // End simulation
        $finish;
    end
    
    // Optional: Monitor the output changes (useful for tracing)
    /*
    always @(out_state_wire) begin
        $display("Time=%0t | Output State Updated:", $time);
        $display("  Row 0: %h %h %h %h", out_state_wire[0][0], out_state_wire[0][1], out_state_wire[0][2], out_state_wire[0][3]);
        // ... and so on
    end
    */

endmodule
