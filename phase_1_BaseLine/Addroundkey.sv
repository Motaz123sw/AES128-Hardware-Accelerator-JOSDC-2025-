module Addroundkey (
    input  logic [7:0] in_state [0:3][0:3],
    input  logic [127:0] round_key,
    output logic [7:0] out_state [0:3][0:3]
);
    integer i, j, k;

    always_comb begin
        for (i = 0; i < 4; i = i + 1) begin      // column
            for (j = 0; j < 4; j = j + 1) begin  // row
                k = i*4 + j;
                out_state[j][i] = in_state[j][i] ^ round_key[127 - k*8 -: 8];
            end
        end
    end
endmodule
