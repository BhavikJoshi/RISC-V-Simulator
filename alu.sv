module alu #(parameter WORD_SIZE = 32, NUM_P_REGS = 64, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000,
				 ALU_XOR = 4'b1000, ALU_SRA = 4'b1001)
	(
		input [ALU_OP_SIZE-1:0] alu_op_i,
		input [WORD_SIZE-1:0] alu_data0_i,
		input [WORD_SIZE-1:0] alu_data1_i,
		output reg [WORD_SIZE-1:0] result_o,
		output zero_o
	);
	
	assign zero_o = result_o == 0;
	
	always @ (*) begin
		case(alu_op_i)
			ALU_ADD: begin
				result_o = alu_data0_i + alu_data1_i;
			end
			ALU_SUB: begin
				result_o = alu_data0_i - alu_data1_i;
			end
			ALU_AND: begin
				result_o = alu_data0_i & alu_data1_i;
			end
			ALU_XOR: begin
				result_o = alu_data0_i ^ alu_data1_i;
			end
			ALU_SRA: begin
				result_o = alu_data0_i >>> alu_data1_i;
			end
			default: begin
				result_o = 0;
			end
		endcase
	end
	
endmodule