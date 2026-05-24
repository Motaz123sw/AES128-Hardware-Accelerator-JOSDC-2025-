module shifter(
input  [7:0]in_state[3:0][3:0],
output reg [7:0]out_state[3:0][3:0]
);

integer i;
integer j;

always @(*) begin

	for (i=0;i<=3;i=i+1) begin
	
		for (j=0;j<=3;j=j+1) begin
				out_state[i][j] = in_state[i][(j+i)%4];
		end
	end
end



endmodule