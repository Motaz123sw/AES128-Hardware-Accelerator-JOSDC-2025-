module async_fifo #(
    parameter WIDTH = 152,
    parameter DEPTH = 16,
    parameter PTR_W = $clog2(DEPTH)
)(
    input  wire                wclk,    // write clock
    input  wire                wrst,    // write-domain reset
    input  wire                w_en,    // write enable
    input  wire [WIDTH-1:0]    wdata,   // write data
    output wire                full,    // FIFO is full (cannot write)

    input  wire                rclk,    // read clock
    input  wire                rrst,    // read-domain reset
    input  wire                r_en,    // read enable
    output reg  [WIDTH-1:0]    rdata,   // read data
    output wire                empty    // FIFO is empty (cannot read)
);

    // FIFO storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // write pointer (binary and gray)
    reg [PTR_W:0] wptr_bin = 0;
    reg [PTR_W:0] wptr_gray = 0;
    reg [PTR_W:0] wptr_gray_sync1 = 0, wptr_gray_sync2 = 0;

    // read pointer (binary and gray)
    reg [PTR_W:0] rptr_bin = 0;
    reg [PTR_W:0] rptr_gray = 0;
    reg [PTR_W:0] rptr_gray_sync1 = 0, rptr_gray_sync2 = 0;

    // Gray/binary conversion
    function [PTR_W:0] bin2gray(input [PTR_W:0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function [PTR_W:0] gray2bin(input [PTR_W:0] gray);
        integer i;
        begin
            gray2bin[PTR_W] = gray[PTR_W];
            for (i = PTR_W-1; i >= 0; i=i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    //--------------------------
    // WRITE CLOCK DOMAIN
    //--------------------------
    always @(posedge wclk or posedge wrst) begin
        if (wrst) begin
            wptr_bin  <= 0;
            wptr_gray <= 0;
        end else begin
            if (w_en && !full) begin
                mem[wptr_bin[PTR_W-1:0]] <= wdata;
                wptr_bin  <= wptr_bin + 1;
                wptr_gray <= bin2gray(wptr_bin + 1);
            end
        end
    end

    // Synchronize read pointer into write clock domain
    always @(posedge wclk or posedge wrst) begin
        if (wrst) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // FULL detection
    assign full =
    (wptr_gray == { ~rptr_gray_sync2[PTR_W], 
                    ~rptr_gray_sync2[PTR_W-1], 
                     rptr_gray_sync2[PTR_W-2:0] });

    //--------------------------
    // READ CLOCK DOMAIN
    //--------------------------
    always @(posedge rclk or posedge rrst) begin
        if (rrst) begin
            rptr_bin  <= 0;
            rptr_gray <= 0;
        end else begin
            if (r_en && !empty) begin
                rdata    <= mem[rptr_bin[PTR_W-1:0]];
                rptr_bin <= rptr_bin + 1;
                rptr_gray <= bin2gray(rptr_bin + 1);
            end
        end
    end

    // Synchronize write pointer into read clock domain
    always @(posedge rclk or posedge rrst) begin
        if (rrst) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // EMPTY detection
    assign empty = (rptr_gray == wptr_gray_sync2);

endmodule
