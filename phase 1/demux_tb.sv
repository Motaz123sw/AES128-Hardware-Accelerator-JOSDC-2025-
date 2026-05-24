`timescale 1ns / 1ps

module demux_tb;
    reg clk;
    reg rst;
    reg din;
    wire aes_out;
    wire comm_out;

    AES uut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .aes_out(aes_out),
        .comm_out(comm_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        din = 1'b1;
        #15;
        rst = 0;
        #250;
        din = 1'b0;
        #100;
        $stop;
    end

    initial begin
        $display("Time | Count | DIN | AES_OUT | COMM_OUT");
        $monitor("%4t |  %d    |  %b   |    %b    |    %b",
                 $time, uut.counter_val, din, aes_out, comm_out);
    end
endmodule