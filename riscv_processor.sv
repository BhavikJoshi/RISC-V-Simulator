module riscv_processor(instruction0, instruction1);

	// ***** Parameters *****
	// Instructions
	localparam PC_SIZE = 32;
	localparam INSTR_SIZE = 32;
	localparam IMM_SIZE = 32;
	localparam MAX_IMEM_ROWS = 4096;
	
	// Registers
	localparam NUM_A_REGS = 32;
	localparam NUM_P_REGS = 64;
	
	// ALU
	localparam ALU_OP_SIZE = 4;
	localparam ALU_ADD = 4'b0010;
	localparam ALU_SUB = 4'b0110;
	localparam ALU_AND = 4'b0000;
	localparam ALU_XOR = 4'b1000;
	localparam ALU_SRA = 4'b1001;
	
	// Declarations
	reg clk;
	
	reg [PC_SIZE-1:0] pc;
	output [INSTR_SIZE-1:0] instruction0;
	output [INSTR_SIZE-1:0] instruction1;
	wire end_of_instructions, if0_done, if1_done;
	
	
	wire [$clog2(NUM_A_REGS)-1:0] rd0, rd1, rs10, rs11, rs20, rs21;
	wire [IMM_SIZE-1:0] imm0, imm1;
	wire [ALU_OP_SIZE-1:0] alu_op0, alu_op1;
	
	initial begin
		pc = 0;
		clk = 0;
		#50 $stop();
	end
	
	// Increment Program Counter
	always begin
		#5 pc = pc + 8;
	end
	
	// Check for end of instruction
	always begin
		/*
		if (end_of_instructions) begin
			$stop("End of Simulation");
		end
		*/
	end
	
	
	// IF STAGE
	instruction_reader #(PC_SIZE, INSTR_SIZE, MAX_IMEM_ROWS) IF0 (.pc_i(pc), .instr_o(instruction0), .done_o(if0_done));
	instruction_reader #(PC_SIZE, INSTR_SIZE, MAX_IMEM_ROWS) IF1 (.pc_i(pc+4), .instr_o(instruction1), .done_o(if1_done));
	assign end_of_instructions = if0_done && if1_done;
	
	// DECODE STAGE
	decode_stage #(INSTR_SIZE, IMM_SIZE, NUM_A_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND, ALU_XOR, ALU_SRA) DE0 (.instr_i(instruction0), .rd_o(rd0), .rs1_o(rs10), .rs2_o(rs20), .imm_o(imm0), .alu_op_o(alu_op0), .control_o());
	decode_stage #(INSTR_SIZE, IMM_SIZE, NUM_A_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND, ALU_XOR, ALU_SRA) DE1 (.instr_i(instruction1), .rd_o(rd1), .rs1_o(rs11), .rs2_o(rs21), .imm_o(imm1), .alu_op_o(alu_op1), .control_o());

endmodule