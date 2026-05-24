//======================================================
//  AddRoundKey Test Module
//======================================================
module test_makersv (
    input  logic clk,
    input  logic rst_n,
    output logic led
);

    logic [7:0] in_state [0:3][0:3];
    logic [7:0] round_key [0:3][0:3];
    logic [7:0] out_state [0:3][0:3];

    // Instantiate the Addroundkey module
    Addroundkey addroundkey_inst (
        .in_state(in_state),
        .round_key(round_key),
        .out_state(out_state)
    );

    // Test vectors for in_state and round_key
    always_comb begin
        in_state[0][0]=8'h00; in_state[0][1]=8'h11; in_state[0][2]=8'h22; in_state[0][3]=8'h33;
        in_state[1][0]=8'h44; in_state[1][1]=8'h55; in_state[1][2]=8'h66; in_state[1][3]=8'h77;
        in_state[2][0]=8'h88; in_state[2][1]=8'h99; in_state[2][2]=8'hAA; in_state[2][3]=8'hBB;
        in_state[3][0]=8'hCC; in_state[3][1]=8'hDD; in_state[3][2]=8'hEE; in_state[3][3]=8'hFF;

        round_key[0][0]=8'h00; round_key[0][1]=8'h01; round_key[0][2]=8'h02; round_key[0][3]=8'h03;
        round_key[1][0]=8'h04; round_key[1][1]=8'h05; round_key[1][2]=8'h06; round_key[1][3]=8'h07;
        round_key[2][0]=8'h08; round_key[2][1]=8'h09; round_key[2][2]=8'h0A; round_key[2][3]=8'h0B;
        round_key[3][0]=8'h0C; round_key[3][1]=8'h0D; round_key[3][2]=8'h0E; round_key[3][3]=8'h0F;
    end

    // LED output driven by least significant bit of first byte in output
    assign led = out_state[0][0][0];

endmodule
