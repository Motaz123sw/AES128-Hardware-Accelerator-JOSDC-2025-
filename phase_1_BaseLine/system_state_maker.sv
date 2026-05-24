module system_state_maker(
    input  wire  [127:0] data_in,
    output logic [7:0] state [0:3][0:3]   // state[row][col]
);

    always_comb begin
        // Column 0
        state[0][0] = data_in[127:120];   // b0
        state[1][0] = data_in[119:112];   // b1
        state[2][0] = data_in[111:104];   // b2
        state[3][0] = data_in[103:96];    // b3

        // Column 1
        state[0][1] = data_in[95:88];     // b4
        state[1][1] = data_in[87:80];     // b5
        state[2][1] = data_in[79:72];     // b6
        state[3][1] = data_in[71:64];     // b7

        // Column 2
        state[0][2] = data_in[63:56];     // b8
        state[1][2] = data_in[55:48];     // b9
        state[2][2] = data_in[47:40];     // b10
        state[3][2] = data_in[39:32];     // b11

        // Column 3
        state[0][3] = data_in[31:24];     // b12
        state[1][3] = data_in[23:16];     // b13
        state[2][3] = data_in[15:8];      // b14
        state[3][3] = data_in[7:0];       // b15
    end

endmodule
