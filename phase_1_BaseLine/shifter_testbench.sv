`timescale 1ns/1ps

module shifter_testbench;

// Testbench signals
reg [7:0] in_state[0:3][0:3];
wire [7:0] out_state[0:3][0:3];

integer i, j;

// Instantiate the shifter
shifter uut (
    .in_state(in_state),
    .out_state(out_state)
);

// Initialize input
initial begin
    // Fill in_state with a known pattern
    // For example, row i has values 0,1,2,3
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_state[i][j] = j; // or any pattern you like
        end
    end

    // Display input
    $display("Initial in_state:");
    for (i = 0; i < 4; i = i + 1) begin
        $display("%d: %d %d %d %d", i, in_state[i][0], in_state[i][1], in_state[i][2], in_state[i][3]);
    end

    // Wait a little for combinational propagation
    #1;

    // Display output
    $display("Output out_state after shifting:");
    for (i = 0; i < 4; i = i + 1) begin
        $display("%d: %d %d %d %d", i, out_state[i][0], out_state[i][1], out_state[i][2], out_state[i][3]);
    end

    $finish;
end

endmodule

