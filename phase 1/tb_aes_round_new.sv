`timescale 1ns/1ps

module tb_aes_round_new;

    // Inputs
    logic [127:0] data_in;
    logic [127:0] key;

    // Internal state
    logic [7:0] state [0:3][0:3];
    logic [7:0] sub_state [0:3][0:3];
    logic [7:0] shifted_state [0:3][0:3];
	 logic [7:0] mixed_state [0:3][0:3];
	 logic [7:0] addkey_state [0:3][0:3];


    // Output
    logic [127:0] data_out;

    // Instantiate modules
    system_state_maker u_state_maker (
        .data_in(data_in),
        .state(state)
    );

    // Simple S-box module (example)
    aes_sbox u_sbox (
        .in_state(state),
        .out_state(sub_state)
    );

    // ShiftRows module
    shifter u_shiftrows (
        .in_state(sub_state),
        .out_state(shifted_state)
    );
	 
	 mix_columns mix_cols_inst (
        .in_state(shifted_state),
        .out_state(mixed_state)
    );
	 
	   Addroundkey add_key_inst (
        .in_state (mixed_state),
        .round_key(key) ,
        .out_state (addkey_state)
    );

    // Data maker module
    data_maker u_data_maker (
        .state(addkey_state),
        .data_out(data_out)
    );
	 
  
	 

    initial begin
        // Test vector from FIPS-197
        data_in = 128'haa8f5f0361dde3ef82d24ad26832469a;  // plaintext
        key     = 128'h3d80477d4716fe3e1e237e446d7a883b;  // round key

        #1; // wait for combinational logic

        // Print state matrices
        $display("Original State:");
        print_state(state);

        $display("After SubBytes:");
        print_state(sub_state);

        $display("After ShiftRows:");
        print_state(shifted_state);
		  
		   $display("After mixcoloumns:");
        print_state(mixed_state);
		  
		   $display("After add round key:");
        print_state(addkey_state);

        $display("Final output (128-bit): %032h", data_out);

        // Compare with expected
        $display("Expected: 486c4eee671d9d0d4de3b138d65f58e7");
        $display("Match: %s", (data_out == 128'h486c4eee671d9d0d4de3b138d65f58e7) ? "YES" : "NO");

        $finish;
    end

    // Task to print a 4x4 state
    task print_state(input logic [7:0] st[0:3][0:3]);
        for (int row=0; row<4; row++) begin
            for (int col=0; col<4; col++) begin
                $write("%02h ", st[row][col]);
            end
            $write("\n");
        end
        $write("\n");
    endtask

endmodule
