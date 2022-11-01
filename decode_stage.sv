module decode_stage #(parameter INSTR_SIZE = 32, A_REG_MOD = 5)
	(
		input [INSTR_SIZE-1:0] instr_i
		output [A_REG_SIZE-1:0] rs1_o;
		output [A_REG_SIZE-1:0] rs2_o;
		output [A_REG_SIZE-1:0] rd_o;
		output [ALU_OP_SIZE-1:0] alu_op_o;
		output control_o;
	);
	
	localparam ALU_OP_SIZE = 4;

	
endmodule
