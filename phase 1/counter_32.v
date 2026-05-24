module counter_32(input wire clk,output reg [4:0] out);


 initial begin
 out = 5'b00000;
 end
 
 always@(clk)
 begin
if (out == 5'b01010)

	out <=5'b00000;
	
	else
	
	out <= out + 1'b1;

end

endmodule