`timescale 1ns/1ps

module tb_data_maker;

    // Inputs
    logic [7:0] state [0:3][0:3]; // row-major state

    // Output
    logic [127:0] data_out;

    // Instantiate the DUT
    data_maker dut (
        .state(state),
        .data_out(data_out)
    );

    integer i, j;

    initial begin
        // Initialize state with example values
        // Row-major: state[row][col]
        state[0][0] = 8'h00; state[0][1] = 8'h01; state[0][2] = 8'h02; state[0][3] = 8'h03;
        state[1][0] = 8'h10; state[1][1] = 8'h11; state[1][2] = 8'h12; state[1][3] = 8'h13;
        state[2][0] = 8'h20; state[2][1] = 8'h21; state[2][2] = 8'h22; state[2][3] = 8'h23;
        state[3][0] = 8'h30; state[3][1] = 8'h31; state[3][2] = 8'h32; state[3][3] = 8'h33;

        #10; // Wait for combinational assignment to propagate

        $display("State (row-major):");
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<4; j=j+1)
                $write("%02h ", state[i][j]);
            $write("\n");
        end

        $display("Data_out: %032h", data_out);

        // Check expected mapping manually if needed
        // Column-major in data_out: 0,1,2,3,4,...,15
        $finish;
    end

endmodule
