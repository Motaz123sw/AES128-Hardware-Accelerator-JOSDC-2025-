module counter_iv_unit (
    input  wire         clk,
    input  wire         rst,

    // ============================================================
    // CONTROL UNIT INTERFACE
    // ============================================================
    // Load Triggers
    input  wire         load_iv_A,      
    input  wire         load_iv_B,      
    
    // IV Data (Full 128-bit Payload)
    input  wire [127:0] iv_data_A,      
    input  wire [127:0] iv_data_B,      

    // Core Selection (0=Stream A, 1=Stream B)
    input  wire         core_0_select,
    input  wire         core_1_select,

    // Mode Selection (1=CTR, 0=Pure/ECB/CBC)
    input  wire         core_0_is_ctr,
    input  wire         core_1_is_ctr,

    // ============================================================
    // CORE INTERFACE
    // ============================================================
    // Pop signals connect to Core 'ififo_en'
    input  wire         core_0_pop, 
    input  wire         core_1_pop, 

    // EOS signals to reset counters (Optional)
    input  wire         core_0_eos, 
    input  wire         core_1_eos,

    // Outputs to Cores
    output reg [127:0]  iv_out_core_0,
    output reg [127:0]  iv_out_core_1
);

    // ============================================================
    // INTERNAL REGISTERS
    // ============================================================
    
    // --- CONTEXT A (Stream 0) ---
    reg [127:0] stored_iv_A;  // Full 128-bit IV
    reg [31:0]  counter_A;    // 32-bit Dynamic Counter
    
    // --- CONTEXT B (Stream 1) ---
    reg [127:0] stored_iv_B;  // Full 128-bit IV
    reg [31:0]  counter_B;    // 32-bit Dynamic Counter

    // ============================================================
    // INCREMENT LOGIC
    // ============================================================
    wire inc_A;
    wire inc_B;
    
    // Increment A if Core 0 or Core 1 pops while assigned to A
    assign inc_A = (core_0_pop && (core_0_select == 1'b0)) || 
                   (core_1_pop && (core_1_select == 1'b0));

    // Increment B if Core 0 or Core 1 pops while assigned to B
    assign inc_B = (core_0_pop && (core_0_select == 1'b1)) || 
                   (core_1_pop && (core_1_select == 1'b1));

    // ============================================================
    // STATE UPDATE
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_iv_A <= 0;
            counter_A   <= 0;
            stored_iv_B <= 0;
            counter_B   <= 0;
        end else begin
            // ------------------------
            // CONTEXT A UPDATE
            // ------------------------
            if (load_iv_A) begin
                stored_iv_A <= iv_data_A;
                // Initialize Counter (Usually starts at 1 for block 1)
                counter_A   <= iv_data_A[31:0]; 
            end else if (inc_A) begin
                counter_A   <= counter_A + 1;
            end
            
            // Reset on EOS (if Stream A ends)
            if ((core_0_eos && core_0_select == 0) || 
                (core_1_eos && core_1_select == 0)) begin
                counter_A <= 0;
            end

            // ------------------------
            // CONTEXT B UPDATE
            // ------------------------
            if (load_iv_B) begin
                stored_iv_B <= iv_data_B;
                counter_B   <= iv_data_B[31:0]; 
            end else if (inc_B) begin
                counter_B   <= counter_B + 1;
            end

            // Reset on EOS (if Stream B ends)
            if ((core_0_eos && core_0_select == 1) || 
                (core_1_eos && core_1_select == 1)) begin
                counter_B <= 0;
            end
        end
    end

    // ============================================================
    // OUTPUT GENERATION (Combinational)
    // ============================================================
    
    // --- Pre-calculate Blocks ---
    wire [127:0] out_A_ctr;
    wire [127:0] out_A_pure;
    wire [127:0] out_B_ctr;
    wire [127:0] out_B_pure;

    // CTR Mode: Upper 96 bits of IV + 32-bit Counter
    assign out_A_ctr = {stored_iv_A[127:32], counter_A};
    assign out_B_ctr = {stored_iv_B[127:32], counter_B};

    // Pure Mode: Full 128-bit stored IV
    assign out_A_pure = stored_iv_A;
    assign out_B_pure = stored_iv_B;

    // --- Muxing for Core 0 ---
    always @(*) begin
        // 1. Select Stream Context (A or B)
        if (core_0_select == 1'b0) begin
            // Stream A
            // 2. Select Mode (CTR or Pure)
            if (core_0_is_ctr) iv_out_core_0 = out_A_ctr;
            else               iv_out_core_0 = out_A_pure;
        end else begin
            // Stream B
            if (core_0_is_ctr) iv_out_core_0 = out_B_ctr;
            else               iv_out_core_0 = out_B_pure;
        end
    end

    // --- Muxing for Core 1 ---
    always @(*) begin
        // 1. Select Stream Context (A or B)
        if (core_1_select == 1'b0) begin
            // Stream A
            if (core_1_is_ctr) iv_out_core_1 = out_A_ctr;
            else               iv_out_core_1 = out_A_pure;
        end else begin
            // Stream B
            if (core_1_is_ctr) iv_out_core_1 = out_B_ctr;
            else               iv_out_core_1 = out_B_pure;
        end
    end

endmodule