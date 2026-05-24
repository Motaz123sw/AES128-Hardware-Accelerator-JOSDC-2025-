/*
 * Module: key_expansion
 * * Implements the AES-128 (10-round) key schedule.
 * - Input:  A 128-bit master key.
 * - Output: An array of 11 128-bit round keys (Round 0 to Round 10).
 */
module key_expansion (
    input logic [127:0] in_key,
	 output logic [127:0] round_keys[0:10]

    
);

reg [7:0] sbox [0:255];
    
    // Initialize the S-box with all 256 values
    initial begin
        // Row 0x00
        // Row 0x00
        sbox[8'h00] = 8'h63; sbox[8'h01] = 8'h7c; sbox[8'h02] = 8'h77; sbox[8'h03] = 8'h7b;//checked correct
        sbox[8'h04] = 8'hf2; sbox[8'h05] = 8'h6b; sbox[8'h06] = 8'h6f; sbox[8'h07] = 8'hc5;//checked correct
        sbox[8'h08] = 8'h30; sbox[8'h09] = 8'h01; sbox[8'h0a] = 8'h67; sbox[8'h0b] = 8'h2b;//checked correct
        sbox[8'h0c] = 8'hfe; sbox[8'h0d] = 8'hd7; sbox[8'h0e] = 8'hab; sbox[8'h0f] = 8'h76;//checked correct
        
        // Row 0x10
        sbox[8'h10] = 8'hca; sbox[8'h11] = 8'h82; sbox[8'h12] = 8'hc9; sbox[8'h13] = 8'h7d;//checked correct
        sbox[8'h14] = 8'hfa; sbox[8'h15] = 8'h59; sbox[8'h16] = 8'h47; sbox[8'h17] = 8'hf0;//checked correct
        sbox[8'h18] = 8'had; sbox[8'h19] = 8'hd4; sbox[8'h1a] = 8'ha2; sbox[8'h1b] = 8'haf;//checked correct
        sbox[8'h1c] = 8'h9c; sbox[8'h1d] = 8'ha4; sbox[8'h1e] = 8'h72; sbox[8'h1f] = 8'hc0;//checked correct
        
        // Row 0x20
        sbox[8'h20] = 8'hb7; sbox[8'h21] = 8'hfd; sbox[8'h22] = 8'h93; sbox[8'h23] = 8'h26;//checked correct
        sbox[8'h24] = 8'h36; sbox[8'h25] = 8'h3f; sbox[8'h26] = 8'hf7; sbox[8'h27] = 8'hcc;//checked correct
        sbox[8'h28] = 8'h34; sbox[8'h29] = 8'ha5; sbox[8'h2a] = 8'he5; sbox[8'h2b] = 8'hf1;//checked correct
        sbox[8'h2c] = 8'h71; sbox[8'h2d] = 8'hd8; sbox[8'h2e] = 8'h31; sbox[8'h2f] = 8'h15;//checked correct
        
        // Row 0x30
        sbox[8'h30] = 8'h04; sbox[8'h31] = 8'hc7; sbox[8'h32] = 8'h23; sbox[8'h33] = 8'hc3;//checked correct
        sbox[8'h34] = 8'h18; sbox[8'h35] = 8'h96; sbox[8'h36] = 8'h05; sbox[8'h37] = 8'h9a;//checked correct
        sbox[8'h38] = 8'h07; sbox[8'h39] = 8'h12; sbox[8'h3a] = 8'h80; sbox[8'h3b] = 8'he2;//checked correct
        sbox[8'h3c] = 8'heb; sbox[8'h3d] = 8'h27; sbox[8'h3e] = 8'hb2; sbox[8'h3f] = 8'h75;//checked correct
        
        // Row 0x40
        sbox[8'h40] = 8'h09; sbox[8'h41] = 8'h83; sbox[8'h42] = 8'h2c; sbox[8'h43] = 8'h1a;//checked correct
        sbox[8'h44] = 8'h1b; sbox[8'h45] = 8'h6e; sbox[8'h46] = 8'h5a; sbox[8'h47] = 8'ha0;//checked correct
        sbox[8'h48] = 8'h52; sbox[8'h49] = 8'h3b; sbox[8'h4a] = 8'hd6; sbox[8'h4b] = 8'hb3;//checked correct
        sbox[8'h4c] = 8'h29; sbox[8'h4d] = 8'he3; sbox[8'h4e] = 8'h2f; sbox[8'h4f] = 8'h84;//checked correct
        
        // Row 0x50
        sbox[8'h50] = 8'h53; sbox[8'h51] = 8'hd1; sbox[8'h52] = 8'h00; sbox[8'h53] = 8'hed;//checked correct
        sbox[8'h54] = 8'h20; sbox[8'h55] = 8'hfc; sbox[8'h56] = 8'hb1; sbox[8'h57] = 8'h5b;//checked correct
        sbox[8'h58] = 8'h6a; sbox[8'h59] = 8'hcb; sbox[8'h5a] = 8'hbe; sbox[8'h5b] = 8'h39;//checked correct
        sbox[8'h5c] = 8'h4a; sbox[8'h5d] = 8'h4c; sbox[8'h5e] = 8'h58; sbox[8'h5f] = 8'hc4;//checked correct
        
        // Row 0x60
        sbox[8'h60] = 8'hd0; sbox[8'h61] = 8'hef; sbox[8'h62] = 8'haa; sbox[8'h63] = 8'hfb;//checked correct
        sbox[8'h64] = 8'h43; sbox[8'h65] = 8'h4d; sbox[8'h66] = 8'h33; sbox[8'h67] = 8'h85;//checked correct
        sbox[8'h68] = 8'h45; sbox[8'h69] = 8'hf9; sbox[8'h6a] = 8'h02; sbox[8'h6b] = 8'h7f;//checked correct
        sbox[8'h6c] = 8'h50; sbox[8'h6d] = 8'h3c; sbox[8'h6e] = 8'h9f; sbox[8'h6f] = 8'ha8;//checked correct
        
        // Row 0x70
        sbox[8'h70] = 8'h51; sbox[8'h71] = 8'ha3; sbox[8'h72] = 8'h40; sbox[8'h73] = 8'h8f;//checked correct
		  sbox[8'h74] = 8'h92; sbox[8'h75] = 8'h9d; sbox[8'h76] = 8'h38; sbox[8'h77] = 8'hf5;//checked correct
		  sbox[8'h78] = 8'hbc; sbox[8'h79] = 8'hb6; sbox[8'h7a] = 8'hda; sbox[8'h7b] = 8'h21;//checked correct
		  sbox[8'h7c] = 8'h10; sbox[8'h7d] = 8'hff; sbox[8'h7e] = 8'hf3; sbox[8'h7f] = 8'hd2;//checked correct
        
        // Row 0x80
        sbox[8'h80] = 8'hcd; sbox[8'h81] = 8'h0c; sbox[8'h82] = 8'h13; sbox[8'h83] = 8'hec;//checked correct
		  sbox[8'h84] = 8'h5f; sbox[8'h85] = 8'h97; sbox[8'h86] = 8'h44; sbox[8'h87] = 8'h17;//checked correct
		  sbox[8'h88] = 8'hc4; sbox[8'h89] = 8'ha7; sbox[8'h8a] = 8'h7e; sbox[8'h8b] = 8'h3d;//checked correct
		  sbox[8'h8c] = 8'h64; sbox[8'h8d] = 8'h5d; sbox[8'h8e] = 8'h19; sbox[8'h8f] = 8'h73;//checked correct
        
        // Row 0x90
        sbox[8'h90] = 8'h60; sbox[8'h91] = 8'h81; sbox[8'h92] = 8'h4f; sbox[8'h93] = 8'hdc;//checked correct
		  sbox[8'h94] = 8'h22; sbox[8'h95] = 8'h2a; sbox[8'h96] = 8'h90; sbox[8'h97] = 8'h88;//checked correct
		  sbox[8'h98] = 8'h46; sbox[8'h99] = 8'hee; sbox[8'h9a] = 8'hb8; sbox[8'h9b] = 8'h14;//checked correct
	     sbox[8'h9c] = 8'hde; sbox[8'h9d] = 8'h5e; sbox[8'h9e] = 8'h0b; sbox[8'h9f] = 8'hdb;//checked correct
        
        // Row 0xA0
        sbox[8'ha0] = 8'he0; sbox[8'ha1] = 8'h32; sbox[8'ha2] = 8'h3a; sbox[8'ha3] = 8'h0a;//checked correct
		  sbox[8'ha4] = 8'h49; sbox[8'ha5] = 8'h06; sbox[8'ha6] = 8'h24; sbox[8'ha7] = 8'h5c;//checked correct
		  sbox[8'ha8] = 8'hc2; sbox[8'ha9] = 8'hd3; sbox[8'haa] = 8'hac; sbox[8'hab] = 8'h62;//checked correct
		  sbox[8'hac] = 8'h91; sbox[8'had] = 8'h95; sbox[8'hae] = 8'he4; sbox[8'haf] = 8'h79;//checked correct
        
        // Row 0xB0
        sbox[8'hb0] = 8'he7; sbox[8'hb1] = 8'hc8; sbox[8'hb2] = 8'h37; sbox[8'hb3] = 8'h6d;//checked correct
		  sbox[8'hb4] = 8'h8d; sbox[8'hb5] = 8'hd5; sbox[8'hb6] = 8'h4e; sbox[8'hb7] = 8'ha9;//checked correct
		  sbox[8'hb8] = 8'h6c; sbox[8'hb9] = 8'h56; sbox[8'hba] = 8'hf4; sbox[8'hbb] = 8'hea;//checked correct
		  sbox[8'hbc] = 8'h65; sbox[8'hbd] = 8'h7a; sbox[8'hbe] = 8'hae; sbox[8'hbf] = 8'h08;//checked correct
        
        // Row 0xC0
        sbox[8'hc0] = 8'hba; sbox[8'hc1] = 8'h78; sbox[8'hc2] = 8'h25; sbox[8'hc3] = 8'h2e;//checked correct
        sbox[8'hc4] = 8'h1c; sbox[8'hc5] = 8'ha6; sbox[8'hc6] = 8'hb4; sbox[8'hc7] = 8'hc6;//checked correct
        sbox[8'hc8] = 8'he8; sbox[8'hc9] = 8'hdd; sbox[8'hca] = 8'h74; sbox[8'hcb] = 8'h1f;//checked correct
        sbox[8'hcc] = 8'h4b; sbox[8'hcd] = 8'hbd; sbox[8'hce] = 8'h8b; sbox[8'hcf] = 8'h8a;//checked correct
        
        // Row 0xD0
        sbox[8'hd0] = 8'h70; sbox[8'hd1] = 8'h3e; sbox[8'hd2] = 8'hb5; sbox[8'hd3] = 8'h66;//checked correct
        sbox[8'hd4] = 8'h48; sbox[8'hd5] = 8'h03; sbox[8'hd6] = 8'hf6; sbox[8'hd7] = 8'h0e;//checked correct
        sbox[8'hd8] = 8'h61; sbox[8'hd9] = 8'h35; sbox[8'hda] = 8'h57; sbox[8'hdb] = 8'hb9;//checked correct
        sbox[8'hdc] = 8'h86; sbox[8'hdd] = 8'hc1; sbox[8'hde] = 8'h1d; sbox[8'hdf] = 8'h9e;//checked correct
		  
        // Row 0xE0
        sbox[8'he0] = 8'he1; sbox[8'he1] = 8'hf8; sbox[8'he2] = 8'h98; sbox[8'he3] = 8'h11;//checked correct
        sbox[8'he4] = 8'h69; sbox[8'he5] = 8'hd9; sbox[8'he6] = 8'h8e; sbox[8'he7] = 8'h94;//checked correct
        sbox[8'he8] = 8'h9b; sbox[8'he9] = 8'h1e; sbox[8'hea] = 8'h87; sbox[8'heb] = 8'he9;//checked correct
        sbox[8'hec] = 8'hce; sbox[8'hed] = 8'h55; sbox[8'hee] = 8'h28; sbox[8'hef] = 8'hdf;//checked correct
        
        // Row 0xF0
        sbox[8'hf0] = 8'h8c; sbox[8'hf1] = 8'ha1; sbox[8'hf2] = 8'h89; sbox[8'hf3] = 8'h0d;//checked correct
        sbox[8'hf4] = 8'hbf; sbox[8'hf5] = 8'he6; sbox[8'hf6] = 8'h42; sbox[8'hf7] = 8'h68;//checked correct
        sbox[8'hf8] = 8'h41; sbox[8'hf9] = 8'h99; sbox[8'hfa] = 8'h2d; sbox[8'hfb] = 8'h0f;//checked correct
        sbox[8'hfc] = 8'hb0; sbox[8'hfd] = 8'h54; sbox[8'hfe] = 8'hbb; sbox[8'hff] = 8'h16;//checked correct
    end

    // --- Round Constants (Rcon) as a synthesizable constant ---
    // The values correspond to Rcon[i/Nk - 1]
		      // --- RCON as 32-bit constants ---
    localparam logic [31:0] RCON [0:9] = '{
        32'h01000000, 32'h02000000, 32'h04000000, 32'h08000000,
        32'h10000000, 32'h20000000, 32'h40000000, 32'h80000000,
        32'h1B000000, 32'h36000000
    };

    // --- Internal storage for all 44 32-bit words ---
    // (11 rounds * 4 words/round)
    logic [31:0] w [0:43];


    // --- Helper Functions (Purely Combinational) ---

    // Rotates a 32-bit word left by one byte (8 bits)
    // [b0, b1, b2, b3] -> [b1, b2, b3, b0]
    function automatic logic [31:0] f_RotWord (input logic [31:0] in_word);
        return {in_word[23:0], in_word[31:24]};
    endfunction

    // Applies the S-Box to all 4 bytes of a 32-bit word
    function automatic logic [31:0] f_SubWord (input logic [31:0] in_word);
        return { sbox[in_word[31:24]],sbox[in_word[23:16]],sbox[in_word[15:8]], sbox[in_word[7:0]] };  
    endfunction


    // --- Main Key Expansion Logic ---
    // This is a single, large combinatorial block that generates all keys.
    always_comb begin
        logic [31:0] temp; // Temporary word for calculations

        // 1. Load the initial master key (Round 0)
        // We split the 128-bit key into the first 4 32-bit words
        w[0] = in_key[127:96]; // Word 0
        w[1] = in_key[95:64];  // Word 1
        w[2] = in_key[63:32];  // Word 2
        w[3] = in_key[31:0];   // Word 3

        // 2. Generate the remaining 40 words (for Rounds 1-10)
        // (Nk = 4 words per key for AES-128)
        for (int i = 4; i < 44; i++) begin
            
            // Get the previous word
            temp = w[i-1];

            // If this is the first word of a new round key (i % Nk == 0)...
            if (i % 4 == 0) begin
                // ...then apply the G-function:
                // 1. Apply RotWord
                // 2. Apply SubWord (using S-Box)
                temp = f_SubWord(f_RotWord(temp));
                
                // 3. XOR the *most significant byte* with the Round Constant
                // RCON index is [i/Nk - 1]
                temp = temp ^ RCON[i/4 - 1];
            end
            
            // Note: For AES-192/256, an 'else if' for SubWord is needed here.
            // For AES-128, no extra step is required.

            // The new word is (word from previous round) XOR (temp)
            // w[i] = w[i - Nk] ^ temp
            w[i] = w[i-4] ^ temp;
        end

        // 3. Map the 44 internal words to the 11 128-bit output keys
        for (int r = 0; r <= 10; r = r + 1) begin
            round_keys[r] = {
                w[r*4 + 0],  // word0 (MSB-to-LSB inside 32-bit word is preserved)
                w[r*4 + 1],
                w[r*4 + 2],
                w[r*4 + 3]
            };

        end
    end

endmodule