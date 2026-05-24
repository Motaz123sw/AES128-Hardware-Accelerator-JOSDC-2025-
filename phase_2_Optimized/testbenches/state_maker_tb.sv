`timescale 1ns/1ps

module state_maker_tb;

    // Inputs
    logic [127:0] data_in;

    // Outputs
    logic [7:0] state [0:3][0:3];

    // Instantiate the DUT
    system_state_maker dut (
        .data_in(data_in),
        .state(state)
    );

    // Test procedure
    initial begin
        // Test vector: 128-bit data
        data_in = 128'h00112233445566778899aabbccddeeff;

        // Wait for combinational logic to propagate
        #1;

        // Print the state matrix
        $display("State matrix (row x col):");
        for (int row = 0; row < 4; row++) begin
            for (int col = 0; col < 4; col++) begin
                $write("%02h ", state[row][col]);
            end
            $write("\n");
        end

        // Another test vector (optional)
        data_in = 128'hffeeddccbbaa99887766554433221100;
        #1;

        $display("\nSecond state matrix:");
        for (int row = 0; row < 4; row++) begin
            for (int col = 0; col < 4; col++) begin
                $write("%02h ", state[row][col]);
            end
            $write("\n");
        end

        $finish;
    end

endmodule
