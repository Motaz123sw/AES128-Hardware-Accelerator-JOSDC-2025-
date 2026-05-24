`timescale 1ns/1ps 

module counter_32_testbench; // Testbench signals 

reg clk; 
wire [4:0] out;

 // Instantiate the counter 
 counter_32 uut ( .clk(clk), .out(out) ); 
 
 // Clock generation: 10 ns period 
 
 initial clk = 0;
 always #5 clk = ~clk; // toggles every 5 ns -> 10 ns period 
 
 // Simulation control 
 initial begin
 $display("Time\tClk\tOut intail"); 
 $display("%0t\t%b\t%0d", $time, clk, out);
 $monitor("%0t\t%b\t%0d", $time, clk, out);
 //Run simulation for 40 clock cycles = 400 ns 
 #400;
 $display("Simulation finished."); $finish;
 
 end endmodule