`timescale 1ns/1ps

module tb_inv_mix_columns;

// Inputs
logic [7:0] in_state[0:3][0:3];

// Output
logic [7:0] out_state[0:3][0:3];

// Instantiate the module
inv_mix_columns uut (
    .in_state(in_state),
    .out_state(out_state)
);

integer i, j;

initial begin
    // Example input (InvSubBytes output)
    // Column-major: each column is [row0,row1,row2,row3]
    in_state[0][0] = 8'h1d; in_state[1][0] = 8'h58; in_state[2][0] = 8'hbb; in_state[3][0] = 8'h0b;
    in_state[0][1] = 8'hf7; in_state[1][1] = 8'h1c; in_state[2][1] = 8'h6c; in_state[3][1] = 8'h64;
    in_state[0][2] = 8'h05; in_state[1][2] = 8'h6e; in_state[2][2] = 8'h6b; in_state[3][2] = 8'ha4;
    in_state[0][3] = 8'h6a; in_state[1][3] = 8'h57; in_state[2][3] = 8'hd9; in_state[3][3] = 8'h04;

    #10; // wait for combinational logic to settle

    // Print the output
    $display("InvMixColumns output:");
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            $write("%02X ", out_state[i][j]);
        end
        $write("\n");
    end

    $finish;
end

endmodule
