
module tb_queue;
    reg clk=0, rst=0, enq=0, deq=0;
    reg [151:0] din;
    wire [151:0] dout;
    wire full, empty;

    queue dut(clk,rst,enq,deq,din,dout,full,empty);

    always #5 clk = ~clk;

    initial begin
        rst=1; #10; rst=0;

        din = 152'hAABBCCDDEEFF00112233445566778899AABB;
        enq=1; #10; enq=0;

        #20 deq=1; #10 deq=0;

        #50 $finish;
    end
endmodule
