
module queue (
    input clk,
    input rst,
    input enq,
    input deq,
    input [151:0] din,
    output [151:0] dout,
    output full,
    output empty
);
    reg [151:0] mem;
    reg valid;

    assign full = valid;
    assign empty = ~valid;
    assign dout = mem;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 0;
        end else begin
            if (enq && !full) begin
                mem <= din;
                valid <= 1;
            end
            if (deq && !empty) begin
                valid <= 0;
            end
        end
    end
endmodule
