module mix_columns (
    input  logic [7:0] in_state[0:3][0:3],
    output logic [7:0] out_state[0:3][0:3]
);

    // Fixed AES MixColumns matrix
    logic [7:0] mixcol_matrix [0:3][0:3] = '{
        '{8'h02, 8'h03, 8'h01, 8'h01},
        '{8'h01, 8'h02, 8'h03, 8'h01},
        '{8'h01, 8'h01, 8'h02, 8'h03},
        '{8'h03, 8'h01, 8'h01, 8'h02}
    };

    // GF(2^8) multiplication by 1,2,3
    function automatic [7:0] mul_gf;
        input [7:0] a;
        input [7:0] b;
        logic [7:0] tmp;
        begin
            if (b == 8'h01) mul_gf = a;
            else if (b == 8'h02) begin
                tmp = a << 1;
                if (a[7]) tmp = tmp ^ 8'h1B;
                mul_gf = tmp & 8'hFF;
            end
            else if (b == 8'h03) begin
                tmp = a << 1;
                if (a[7]) tmp = tmp ^ 8'h1B;
                mul_gf = (tmp ^ a) & 8'hFF;
            end
            else mul_gf = 8'h00;
        end
    endfunction

    integer i, j, k;

    always_comb begin
        for (j = 0; j < 4; j = j + 1) begin        // loop over columns
            for (i = 0; i < 4; i = i + 1) begin    // loop over rows
                out_state[i][j] = 8'h00;
                for (k = 0; k < 4; k = k + 1) begin
                    out_state[i][j] = out_state[i][j] ^ mul_gf(in_state[k][j], mixcol_matrix[i][k]);
                end
            end
        end
    end

endmodule
