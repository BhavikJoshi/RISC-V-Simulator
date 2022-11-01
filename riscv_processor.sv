module riscv_processor(o0, o1);

	localparam PC_SIZE = 32;
	localparam INSTR_SIZE = 32;
	localparam NUM_A_REGS = 32, A_REG_MOD = 5;
	localparam NUM_P_REGS = 64, P_REG_MOD = 6;
	
	reg [PC_SIZE-1:0] pc;
	
	
	wire [INSTR_SIZE-1:0] instruction0;
	wire [INSTR_SIZE-1:0] [31:0] instruction1;
	wire end_of_instructions;
	
	initial begin
		pc = 0;
		#200 $stop();
	end
	
	always begin
		#5 pc = pc + 8;
	end
	
	instruction_reader #(PC_SIZE, INSTR_SIZE) ifetch (.pc0_i(pc), .pc1_i(pc+4), .instr0_o(instruction0), .instr1_o(instruction1), .done_o(end_of_instructions));

endmodule