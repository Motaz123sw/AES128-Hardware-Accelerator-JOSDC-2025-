module AES_last_round (
    input  logic [127:0] data_in,
    input  logic [127:0] round_key,
    output logic [127:0] data_out
);
    // Internal wires
    logic [7:0] state_initial[0:3][0:3];
    logic [7:0] state_after_sbox[0:3][0:3];
    logic [7:0] state_after_shift[0:3][0:3];
    logic [7:0] state_after_addkey[0:3][0:3];

    // 1. Convert 128-bit flat vector to 4x4 State Matrix
    system_state_maker state_maker_inst (
        .data_in (data_in),
        .state   (state_initial)
    );

    // 2. SubBytes
    aes_sbox sbox_inst (
        .in_state (state_initial),
        .out_state(state_after_sbox)
    );

    // 3. ShiftRows
    shifter shifter_inst (
        .in_state (state_after_sbox),
        .out_state(state_after_shift)
    );

    // --- SKIP MIX COLUMNS ---

    // 4. AddRoundKey
    Addroundkey add_key_inst (
        .in_state (state_after_shift),
        .round_key(round_key),
        .out_state (state_after_addkey)
    );

    // 5. Convert 4x4 State Matrix back to 128-bit flat vector
    data_maker data_maker_inst (
        .state   (state_after_addkey),
        .data_out(data_out)
    );

endmodule