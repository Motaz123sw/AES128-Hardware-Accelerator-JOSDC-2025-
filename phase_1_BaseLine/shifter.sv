module shifter(
    input  logic [7:0] in_state[0:3][0:3],
    output logic [7:0] out_state[0:3][0:3]
);

always @(*) begin
    // Row 0: no shift
    out_state[0][0] = in_state[0][0];
    out_state[0][1] = in_state[0][1];
    out_state[0][2] = in_state[0][2];
    out_state[0][3] = in_state[0][3];

    // Row 1: shift left by 1
    out_state[1][0] = in_state[1][1];
    out_state[1][1] = in_state[1][2];
    out_state[1][2] = in_state[1][3];
    out_state[1][3] = in_state[1][0];

    // Row 2: shift left by 2
    out_state[2][0] = in_state[2][2];
    out_state[2][1] = in_state[2][3];
    out_state[2][2] = in_state[2][0];
    out_state[2][3] = in_state[2][1];

    // Row 3: shift left by 3 (or right by 1)
    out_state[3][0] = in_state[3][3];
    out_state[3][1] = in_state[3][0];
    out_state[3][2] = in_state[3][1];
    out_state[3][3] = in_state[3][2];
end

endmodule
