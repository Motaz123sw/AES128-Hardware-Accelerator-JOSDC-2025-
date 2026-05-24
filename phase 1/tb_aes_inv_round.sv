`timescale 1ns/1ps

module tb_aes_inv_round;

    // Inputs
    logic [127:0] data_in;
    logic [127:0] key;

    // Internal state
    logic [7:0] state [0:3][0:3];
    logic [7:0] inv_shift_state [0:3][0:3];
    logic [7:0] inv_sub_state [0:3][0:3];
    logic [7:0] inv_mix_state [0:3][0:3];
    logic [7:0] addkey_state [0:3][0:3];

    // Output
    logic [127:0] data_out;

    // Instantiate modules
    system_state_maker u_state_maker (
        .data_in(data_in),
        .state(state)
    );
	 
	     Addroundkey add_key_inst (
        .in_state(state),
        .round_key(key),
        .out_state(addkey_state)
    );
    // Inverse MixColumns
    inv_mix_columns u_inv_mix (
        .in_state(addkey_state),
        .out_state(inv_mix_state)
    );

    // Inverse ShiftRows
    inv_shifter u_inv_shift (
        .in_state(inv_mix_state),
        .out_state(inv_shift_state)
    );

    // Inverse SubBytes
    inv_sbox u_inv_sbox (
        .in_state(inv_shift_state),
        .out_state(inv_sub_state)
    );
	 



    // Convert matrix back to vector
    data_maker u_data_maker (
        .state(inv_sub_state),
        .data_out(data_out)
    );

    initial begin
        // Example inverse-round test vector (you can change it later)
        data_in = 128'ha49c7ff2689f352b6b5bea43026a5049; // ciphertext after 1 round a49c7ff2689f352b6b5bea43026a5049  89B5884AC05653032E389B21604D123C
        key     = 128'ha0fafe1788542cb123a339392a6c7605; // same round key

        #1;

        $display("Initial (Ciphertext) State:");
        print_state(state);

        $display("After InvShiftRows:");
        print_state(inv_shift_state);

        $display("After InvSubBytes:");
        print_state(inv_sub_state);
		  
		  $display("After AddRoundKey:");
        print_state(addkey_state);

        $display("After InvMixColumns:");
        print_state(inv_mix_state);



        $display("Final output (128-bit): %032h", data_out);
		  
		  // Compare with expected
        $display("Expected: 193de3bea0f4e22b9ac68d2ae9f84808");
        $display("Match: %s", (data_out == 128'h193de3bea0f4e22b9ac68d2ae9f84808) ? "YES" : "NO");

        $finish;
    end

    // Task to print a 4x4 state matrix
    task print_state(input logic [7:0] st[0:3][0:3]);
        for (int row = 0; row < 4; row++) begin
            for (int col = 0; col < 4; col++) begin
                $write("%02h ", st[row][col]);
            end
            $write("\n");
        end
        $write("\n");
    endtask

endmodule
