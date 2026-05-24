module inv_mix_columns (
input  logic [7:0] in_state[0:3][0:3],
output logic [7:0] out_state[0:3][0:3]
);


// AES Inverse MixColumns matrix coefficients
logic [7:0] inv_mixcol_matrix [0:3][0:3] = '{
    '{8'h0E, 8'h0B, 8'h0D, 8'h09},
    '{8'h09, 8'h0E, 8'h0B, 8'h0D},
    '{8'h0D, 8'h09, 8'h0E, 8'h0B},
    '{8'h0B, 8'h0D, 8'h09, 8'h0E}
};

// Multiply by 2 in GF(2^8)
function automatic [7:0] xtime;
    input [7:0] x;
    begin
        xtime = {x[6:0], 1'b0} ^ (8'h1B & {8{x[7]}});
    end
endfunction

// GF(2^8) multiplication for inverse coefficients
function automatic [7:0] mul_gf;
    input [7:0] a;
    input [7:0] b;
    reg [7:0] t;
    begin
        case(b)
            8'h01: mul_gf = a;
            8'h02: mul_gf = xtime(a);
            8'h03: mul_gf = xtime(a) ^ a;
            8'h09: mul_gf = xtime(xtime(xtime(a))) ^ a;
            8'h0B: mul_gf = xtime(xtime(xtime(a)) ^ a) ^ a;
            8'h0D: mul_gf = xtime(xtime(xtime(a) ^ a)) ^ a;
            8'h0E: mul_gf = xtime(xtime(xtime(a) ^ a) ^ a);
            default: mul_gf = 8'h00;
        endcase
    end
endfunction

integer i, j, k;

always_comb begin
    for (j = 0; j < 4; j = j + 1) begin        // loop over columns
        for (i = 0; i < 4; i = i + 1) begin    // loop over rows
            out_state[i][j] = 8'h00;
            for (k = 0; k < 4; k = k + 1) begin
                out_state[i][j] ^= mul_gf(in_state[k][j], inv_mixcol_matrix[i][k]);
            end
        end
    end
end


endmodule
