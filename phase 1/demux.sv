`timescale 1ns / 1ps

module demux (
    input  wire       din,
    input  wire [3:0] counter,
    output reg        aes_out,
    output reg        comm_out
);
    always @(*) begin
        if (counter == 4'd10) begin
            comm_out = din;
            aes_out  = 1'b0;
        end else begin
            aes_out  = din;
            comm_out = 1'b0;
        end
    end
endmodule