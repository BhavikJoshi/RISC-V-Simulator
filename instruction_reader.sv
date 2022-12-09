module instruction_reader #(parameter PC_SIZE = 32, INSTR_SIZE = 32, MAX_LINES = 4096)
	(
		input reg [PC_SIZE-1:0] pc_i,
		output reg [INSTR_SIZE-1:0] instr_o,
		output done_o
	);

	localparam BYTE_SIZE = 8;
	localparam NOP = 32'b0;
	
	// Instruction Storage
	reg [BYTE_SIZE-1:0] instr_mem [0:MAX_LINES-1];


	// Load file binary into register
	initial begin
		$readmemh("C:/Users/piefo/OneDrive/Desktop/189/bin.txt", instr_mem);
	end
	
	// Fetch instruction from i-memory
	assign instr_o = instr_mem[pc_i+3] !== 8'bxxxxxxxx ? {instr_mem[pc_i+0], instr_mem[pc_i+1], instr_mem[pc_i+2], instr_mem[pc_i+3]} : NOP;
	
	// If no more instructions
	assign done_o = (instr_mem[pc_i+3] === 8'bxxxxxxxx);
	

endmodule

