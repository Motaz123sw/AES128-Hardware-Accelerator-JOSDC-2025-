module aes128_decrypt_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [127:0] block_in,
    input  logic [127:0] round_keys [0:10],

    output logic        done,
    output logic [127:0] plain_text,
    output logic [127:0] round_regs [0:10]
);

// Internal registers
logic [127:0] state;
logic [3:0]   round_counter; // 0..11 used
logic         running;

// Next state wires
logic [127:0] state_after_round;
logic [127:0] state_after_first;
logic [127:0] state_next;

// selected key for the instantiated round module
logic [127:0] selected_round_key;

// Choose the key used by the structural inv round module.
// When round_counter==1 we want key[10] (special first decrypt round).
// Otherwise we want round_keys[11 - round_counter] for rounds 2..10.
always_comb begin
    if (round_counter == 1)
        selected_round_key = round_keys[10];
    else if ((round_counter >= 2) && (round_counter <= 10))
        selected_round_key = round_keys[11 - round_counter];
    else
        selected_round_key = 128'h0; // unused
end

// --- Round modules (structural instantiation) ---
// Connect the dynamic selected_round_key (avoid indexing array in port list).
inv_AES_round u_round (
    .Cipher_text(state),
    .Round_key(selected_round_key),
    .Plain_text(state_after_round)
);

inv_AES_first_round u_first (
    .Cipher_text(state),
    .Round_key(round_keys[10]),   // first-round key is fixed = key[10]
    .Plain_text(state_after_first)
);

// --- Sequential AES control ---
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= 128'h0;
        round_counter <= 0;
        running <= 0;
        done <= 0;
        // optional: initialize round_regs
        for (int i = 0; i <= 10; i = i + 1) begin
            round_regs[i] <= 128'h0;
        end
    end else begin
        if (start && !running) begin
            // load input and start on next cycle
            state <= block_in;
            round_regs[0] <= block_in;    // explicitly store round 0 = input
            round_counter <= 1;           // next cycle will process round 1
            running <= 1;
            done <= 0;
        end else if (running) begin
            if (round_counter <= 10) begin
                // pick output of the appropriate combinational module
                if (round_counter == 1)
                    state_next = state_after_first;
                else
                    state_next = state_after_round;

                state <= state_next;
                round_regs[round_counter] <= state_next;
                round_counter <= round_counter + 1;
            end else begin
                // finished all 10 rounds (round_counter == 11 after increment)
                running <= 0;
                done <= 1;
            end
        end else begin
            // idle
            done <= 0;
        end
    end
end

// Final AddRoundKey with key[0] — only do this if your round modules do not perform key[0] add.
assign plain_text = state ^ round_keys[0];

endmodule
