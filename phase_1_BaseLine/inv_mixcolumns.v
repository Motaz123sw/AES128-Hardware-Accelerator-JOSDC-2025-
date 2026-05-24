module inv_mix_columns (
input  logic [7:0] in_state[0:3][0:3],
output logic [7:0] out_state[0:3][0:3]
);

```
// AES Inverse MixColumns matrix
logic [7:0] inv_mixcol_matrix [0:3][0:3] = '{
    '{8'h0E, 8'h0B, 8'h0D, 8'h09},
    '{8'h09, 8'h0E, 8'h0B, 8'h0D},
    '{8'h0D, 8'h09, 8'h0E, 8'h0B},
    '{8'h0B, 8'h0D, 8'h09, 8'h0E}
};

// GF(2^8) multiplication
function automatic [7:0] mul_gf;
    input [7:0] a;
    input [7:0] b;
    logic [7:0] t;
    begin
        case(b)
            8'h01: mul_gf = a;
            8'h02: begin
                t = a << 1;
                if (a[7]) t = t ^ 8'h1B;
                mul_gf = t & 8'hFF;
            end
            8'h03: begin
                t = a << 1;
                if (a[7]) t = t ^ 8'h1B;
                mul_gf = (t ^ a) & 8'hFF;
            end
            8'h09: begin
                t = a << 1; if(a[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                mul_gf = t ^ a;
            end
            8'h0B: begin
                t = a << 1; if(a[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t ^ a;
                mul_gf = t ^ a; // combine steps for 0x0B
            end
            8'h0D: begin
                t = a << 1; if(a[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t ^ a;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                mul_gf = t ^ a; // 0x0D
            end
            8'h0E: begin
                t = a << 1; if(a[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                t = t ^ a;
                t = t << 1; if(t[7]) t = t ^ 8'h1B; t &= 8'hFF;
                mul_gf = t & 8'hFF; // 0x0E
            end
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
                out_state[i][j] = out_state[i][j] ^ mul_gf(in_state[k][j], inv_mixcol_matrix[i][k]);
            end
        end
    end
end
```

endmodule
