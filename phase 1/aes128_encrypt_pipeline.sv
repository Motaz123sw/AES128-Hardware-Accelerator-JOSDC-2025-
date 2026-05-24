module aes128_encrypt_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [127:0] block_in,
    input  logic [127:0] round_keys [0:10],

    output logic        done,
    output logic [127:0] cipher_text,
    output logic [127:0] round_regs [0:10]
);

// Internal registers
logic [127:0] state;
logic [3:0]   round_counter;
logic         running;

// Next state wires
logic [127:0] state_after_round;
logic [127:0] state_after_final;
logic [127:0] state_next;

// --- Round modules (structural instantiation) ---
AES_round u_round (
    .Plain_text(state),
    .Round_key(round_keys[round_counter]),
    .cipher_text(state_after_round)
);

AES_last_round u_final (
    .data_in(state),
    .round_key(round_keys[round_counter]),
    .data_out(state_after_final)
);


// --- Sequential AES control ---
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= 0;
        round_counter <= 0;
        running <= 0;
        done <= 0;
    end else begin
        if (start && !running) begin
            state <= block_in ^ round_keys[0];
            round_regs[0] <= block_in ^ round_keys[0];
            round_counter <= 1;
            running <= 1;
            done <= 0;
        end else if (running) begin
            if (round_counter < 11) begin
				    if (round_counter < 10)
						state_next = state_after_round;
					 else begin
						state_next = state_after_final;
					 end
                state <= state_next;
                round_regs[round_counter] <= state_next;
                round_counter <= round_counter + 1;
            end else begin
                running <= 0;
                done <= 1;
            end
        end
    end
end

assign cipher_text = state;

endmodule
