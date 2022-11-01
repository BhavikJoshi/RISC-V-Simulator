module instruction_reader #(parameter PC_SIZE = 32, INSTR_SIZE = 32)
	(
		input reg [PC_SIZE-1:0] pc0_i,
		input reg [PC_SIZE-1:0] pc1_i,
		output reg [INSTR_SIZE-1:0] instr0_o,
		output reg [INSTR_SIZE-1:0] instr1_o,
		output done_o
	);

	localparam BYTE_SIZE = 8;
	localparam MAX_LINES = 1024;
	localparam NOP = 32'b0;
	
	// Instruction Storage
	reg [BYTE_SIZE-1:0] instr_mem [0:MAX_LINES-1];


	// Load file binary into register
	initial begin
		$readmemh("D:/Users/Bhavik/OneDrive/Desktop/Quartus/bin.txt", instr_mem);
	end
	
	// Return instructions at PCs
	always @ (*) begin
		instr0_o = instr_mem[pc0_i+3] !== 8'bxxxxxxxx ? {instr_mem[pc0_i+3], instr_mem[pc0_i+2], instr_mem[pc0_i+1], instr_mem[pc0_i]} : NOP;
		instr1_o = instr_mem[pc1_i+3] !== 8'bxxxxxxxx ? {instr_mem[pc1_i+3], instr_mem[pc1_i+2], instr_mem[pc1_i+1], instr_mem[pc1_i]} : NOP;
	end
	
	// If no more instructions
	assign done_o = (instr_mem[pc0_i+3] === 8'bxxxxxxxx && instr_mem[pc1_i+3] === 8'bxxxxxxxx);
	

endmodule

