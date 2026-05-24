module core (
    input  wire         rst,
    input  wire         clk,
    input  wire [151:0] input_packet_core,
    input  wire [127:0] counter_core,
    input  wire         read_done_core,
    
    input  wire         ififo_en_core,
    input  wire         ofull_core,
	 input  wire         is_eos_core,

    output reg  [151:0] output_packet_core,
    output reg          valid_core,
    output reg          full_core,
    output reg          new_stream_core,
    output reg          ififo_en
);

    wire key_expan_go;
    wire key_expan_done;
    wire [127:0] active_round_keys [0:10];
    
    // --- FIX: Widen this wire to 152 bits ---
    wire [151:0] ififo_data; 
    
    wire ififo_empty;
    wire ififo_rst;
    wire [127:0] main_key_from_aes;
	 

    key_expansion_fsm u_key_expan (
        .clk(clk),
        .rst(rst),
        .go(key_expan_go),
        .key_in(main_key_from_aes),
        .done(key_expan_done),
        .round_keys(active_round_keys)
    );

    async_fifo #(.WIDTH(152), .DEPTH(16)) u_aes_in_fifo (
        .wclk(clk), .wrst(rst),
        .w_en(ififo_en_core), .wdata(input_packet_core), .full(full_core),
        
        .rclk(clk), .rrst(ififo_rst),
        .r_en(ififo_en), .rdata(ififo_data), .empty(ififo_empty)
    );

    aes_fsm_V2 u_aes_fsm(
        .clk(clk),
        .rst(rst),

        .start(key_expan_done),           
        .input_fifo_empty(ififo_empty),   
        .output_fifo_full(ofull_core),    

        .round_keys(active_round_keys),
        .input_packet(ififo_data),        
        .counter(counter_core),
        .read_done(read_done_core),
     
        .output_packet(output_packet_core),
        .valid(valid_core),
        .rst_ififo(ififo_rst),
        .en_ififo(ififo_en),
        .key_expan_go(key_expan_go),
        .main_key(main_key_from_aes),
        .new_stream(new_stream_core),
		  .is_eos(is_eos_core)
    );

endmodule