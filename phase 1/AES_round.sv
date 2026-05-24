/*
 * This module implements one standard round of AES encryption, which consists of:
 * 1. SubBytes (aes_sbox)
 * 2. ShiftRows (system_shifter)
 * 3. MixColumns (mix_columns)
 * 4. AddRoundKey (Addroundkey)
 *
 * It also includes the necessary state-to-vector and vector-to-state converters.
 * This does NOT represent the final round (which omits MixColumns) or the
 * initial AddRoundKey.
 */
module AES_round (
    input  logic [127:0] Plain_text,
    input  logic [127:0] Round_key,
    output logic [127:0] cipher_text
);

    // After converting 128-bit input to 4x4 state
    logic [7:0] after_maker[0:3][0:3];
	     // After SubBytes
    logic [7:0] after_sbox[0:3][0:3];
	     // After ShiftRows
    logic [7:0] after_shift[0:3][0:3];
	 // After MixColumns
    wire [7:0] after_mix[0:3][0:3];
	 // After AddRoundKey
    wire [7:0] after_add_key[0:3][0:3];
	 // Wire for the final 128-bit output vector
    wire [127:0] after_data_maker;

    system_state_maker state_maker_inst (
        .data_in(Plain_text),
        .state(after_maker)
    );



    aes_sbox sbox_inst (
        .in_state(after_maker) ,
        .out_state (after_sbox)
    );
    


    shifter shifter_inst (
        .in_state(after_sbox),
        .out_state(after_shift)
    );

    

    mix_columns mix_cols_inst (
        .in_state(after_shift),
        .out_state(after_mix)
    );

    

    Addroundkey add_key_inst (
        .in_state (after_mix),
        .round_key(Round_key) ,
        .out_state (after_add_key)
    );
    
    

    // Convert 4x4 state back to 128-bit vector
    // Note: Corrected module name from 'data_maker' to 'system_data_maker'
    data_maker data_maker_inst (
        .state (after_add_key),
        .data_out(cipher_text)
    );

    // Assign the final vector to the module's output
    // Using 'assign' is cleaner for simple combinational assignment
    //assign cipher_text = after_data_maker;

endmodule

