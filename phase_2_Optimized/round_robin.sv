module round_robin #(  
    parameter DATA_WIDTH = 128
) (  
    input  logic                    clk,  
    input  logic                    reset,  
  
    input  logic [DATA_WIDTH-1:0]   data_in0,       // Core 0 ciphertext  
    input  logic [DATA_WIDTH-1:0]   data_in1,       // Core 1 ciphertext  
    input  logic                    valid0,         // Core 0 output ready  
    input  logic                    valid1,         // Core 1 output ready  
  
    input  logic                    fifo_full,      // FIFO back-pressure  
  
    output logic                    readDone0,      // Ack to core 0  
    output logic                    readDone1,      // Ack to core 1  
    output logic [DATA_WIDTH-1:0]   dataOut,        // Data to FIFO  
    output logic                    fifoEnable,     // Write enable to FIFO  
    output logic                    fifoReset       // Reset to FIFO  
);  
  
    typedef enum logic {  
        CORE0_TURN = 1'b0,  
        CORE1_TURN = 1'b1  
    } state_t;  
  
    state_t current_state, next_state;  
  
    logic grant0;  
    logic grant1;  
  
    always_ff @(posedge clk) begin  
        if (reset)  
            current_state <= CORE0_TURN;  
        else  
            current_state <= next_state;  
    end  
  
    always_comb begin  
        case (current_state)  
            CORE0_TURN : next_state = CORE1_TURN;  
            CORE1_TURN : next_state = CORE0_TURN;  
            default    : next_state = CORE0_TURN;  
        endcase  
    end  
  
    always_comb begin  
        grant0 = 1'b0;  
        grant1 = 1'b0;  
  
        case (current_state)  
            CORE0_TURN: begin  
                if (valid0 && !fifo_full)  
                    grant0 = 1'b1;  
                else if (valid1 && !fifo_full)  
                    grant1 = 1'b1;  
            end  
  
            CORE1_TURN: begin  
                if (valid1 && !fifo_full)  
                    grant1 = 1'b1;  
                else if (valid0 && !fifo_full)  
                    grant0 = 1'b1;  
            end  
  
            default: begin  
                grant0 = 1'b0;  
                grant1 = 1'b0;  
            end  
        endcase  
    end  
  
    assign readDone0  = grant0;  
    assign readDone1  = grant1;  
    assign dataOut    = grant0 ? data_in0 : data_in1;  
    assign fifoEnable = grant0 | grant1;  
    assign fifoReset  = reset;  
  
endmodule