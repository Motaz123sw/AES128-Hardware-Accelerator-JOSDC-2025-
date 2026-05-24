module inv_AES_round (
input  logic [127:0] Cipher_text,
input  logic [127:0] Round_key,
output logic [127:0] Plain_text
);

// Convert 128-bit input to 4x4 state
logic [7:0] after_maker[0:3][0:3];
// After InvShiftRows
logic [7:0] after_inv_shift[0:3][0:3];
// After InvSubBytes
logic [7:0] after_inv_sbox[0:3][0:3];
// After InvMixColumns
wire [7:0] after_inv_mix[0:3][0:3];
// After AddRoundKey
wire [7:0] after_add_key[0:3][0:3];

// Convert input vector to state matrix
system_state_maker state_maker_inst (
    .data_in(Cipher_text),
    .state(after_maker)
);

// AddRoundKey (same as encryption)
Addroundkey add_key_inst (
    .in_state(after_maker),
    .round_key(Round_key),
    .out_state(after_add_key)
);

// Inverse MixColumns
inv_mix_columns inv_mix_inst (
    .in_state(after_add_key),
    .out_state(after_inv_mix)
);

// Inverse ShiftRows
inv_shifter inv_shifter_inst (
    .in_state(after_inv_mix),
    .out_state(after_inv_shift)
);

// Inverse SubBytes
inv_sbox inv_sbox_inst (
    .in_state(after_inv_shift),
    .out_state(after_inv_sbox)
);

// Convert 4x4 state back to 128-bit vector
data_maker data_maker_inst (
    .state(after_inv_sbox),
    .data_out(Plain_text)
);


endmodule
