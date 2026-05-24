module data_maker(
    input  logic [7:0] state [0:3][0:3], // state[row][col]
    output logic [127:0] data_out
);

    always@(*) begin
data_out[127:120] = state[0][0]; // Column 0, Row 0
data_out[119:112] = state[1][0]; // Column 0, Row 1
data_out[111:104] = state[2][0]; // Column 0, Row 2
data_out[103:96]  = state[3][0]; // Column 0, Row 3

data_out[95:88]   = state[0][1]; // Column 1, Row 0
data_out[87:80]   = state[1][1]; // Column 1, Row 1
data_out[79:72]   = state[2][1]; // Column 1, Row 2
data_out[71:64]   = state[3][1]; // Column 1, Row 3

data_out[63:56]   = state[0][2]; // Column 2
data_out[55:48]   = state[1][2];
data_out[47:40]   = state[2][2];
data_out[39:32]   = state[3][2];

data_out[31:24]   = state[0][3]; // Column 3
data_out[23:16]   = state[1][3];
data_out[15:8]    = state[2][3];
data_out[7:0]     = state[3][3];

    end

endmodule
