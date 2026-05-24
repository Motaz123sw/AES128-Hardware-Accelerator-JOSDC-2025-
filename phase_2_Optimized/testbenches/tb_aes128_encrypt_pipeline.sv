`timescale 1ns/1ps

module tb_aes128_encrypt_pipeline;

// --- Clock and reset ---
logic clk;
logic rst_n;

// --- Inputs to DUT ---
logic start;
logic [127:0] block_in;
logic [127:0] tb_key;
logic [127:0] round_keys [0:10];

// --- Outputs from DUT ---
logic done;
logic [127:0] block_out;
logic [127:0] round_regs [0:10];

// --- Clock generation ---
initial clk = 0;
always #5 clk = ~clk; // 100 MHz

// --- Reset generation ---
initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
end

// --- Key expansion instance ---
key_expansion key_exp_inst (
    .in_key(tb_key),
    .round_keys(round_keys)
);

// --- DUT instance ---
aes128_encrypt_pipeline dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .block_in(block_in),
    .round_keys(round_keys),
    .done(done),
    .cipher_text(block_out),
    .round_regs(round_regs)
);

// --- Stimulus ---
initial begin
    // Wait for reset
    @(posedge rst_n);

    $display("=== Starting AES128 Encryption Test ===");

    // Initialize inputs
    tb_key   = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
    block_in = 128'hF69F2445DF4F9B17AD2B417BE66C3710;

    // Start encryption
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait until DUT finishes all 10 rounds
    wait(done);

    // Print final result
    $display("==============================================");
    $display("Encryption finished at time %0t", $time);
    $display("Ciphertext = %h", block_out);
    $display("Expected   = 7B0C785E27E8AD3F8223207104725DD4");
	 if(block_out==128'h7B0C785E27E8AD3F8223207104725DD4)begin
		$display("pass");
	 end else begin
		$display("fail");
		end
    $display("==============================================");

    // Print all internal round register states
    for (int i = 0; i <= 10; i++) begin
        $display("Round %0d output = %h", i, round_regs[i]);
    end
    $display("==============================================");

    $finish;
end

endmodule
