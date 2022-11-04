module decode_stage #(parameter INSTR_SIZE = 32, IMM_SIZE = 32, NUM_A_REGS = 32, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000, ALU_XOR = 4'b1000, ALU_SRA = 4'b1001)
	(
		input [INSTR_SIZE-1:0] instr_i,
		output reg [$clog2(NUM_A_REGS)-1:0] rd_o,
		output reg [$clog2(NUM_A_REGS)-1:0] rs1_o,
		output reg [$clog2(NUM_A_REGS)-1:0] rs2_o, 
		output reg [IMM_SIZE-1:0] imm_o,
		output reg [ALU_OP_SIZE-1:0] alu_op_o,
		output control_o
	);
	
	// Instruction type opcodes
	localparam OPCODE_MSB = 6;
	localparam OPCODE_SIZE = 7;
	localparam R_TYPE = 7'b0110011;
	localparam I_TYPE = 7'b0010011;
	localparam L_TYPE = 7'b0000011;
	localparam S_TYPE = 7'b0100011;
	
	localparam RD_MSB = 11;
	localparam RS1_MSB = 19;
	localparam RS2_MSB = 24;
	localparam FUNCT3_MSB = 14;
	localparam FUNCT7_MSB = 31;
	
	assign control_o = 1'b1;
	
	// Rd
	always @ (*) begin
		case(instr_i[OPCODE_MSB:OPCODE_MSB - OPCODE_SIZE + 1])
			R_TYPE, I_TYPE, L_TYPE: begin
				rd_o = instr_i[RD_MSB:RD_MSB - $clog2(NUM_A_REGS) + 1];
			end
			default: begin
				rd_o = 0;
			end
		endcase
	end
	
	// Rs1
	always @ (*) begin
		case(instr_i[OPCODE_MSB:OPCODE_MSB - OPCODE_SIZE + 1])
			R_TYPE, I_TYPE, L_TYPE, S_TYPE: begin
				rs1_o = instr_i[RS1_MSB:RS1_MSB - $clog2(NUM_A_REGS) + 1];
			end
			default: begin
				rs1_o = 0;
			end
		endcase
	end
	
	// Rs2
	always @ (*) begin
		case(instr_i[OPCODE_MSB:OPCODE_MSB - OPCODE_SIZE + 1])
			R_TYPE, S_TYPE: begin
				rs2_o = instr_i[RS2_MSB:RS2_MSB - $clog2(NUM_A_REGS) + 1];
			end
			default: begin
				rs2_o = 0;
			end
		endcase
	end
	
	// Immediate
	always @ (*) begin
		case(instr_i[OPCODE_MSB:OPCODE_MSB - OPCODE_SIZE + 1])
			I_TYPE, L_TYPE: begin
				imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
			end
			S_TYPE: begin
				imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
			end
			default: begin
				imm_o = 0;
			end
		endcase
	end
	
	// Control Signals (Including ALU OP)
	always @ (*) begin
		case(instr_i[OPCODE_MSB:OPCODE_MSB - OPCODE_SIZE + 1])
			R_TYPE: begin
				// ADD
				if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b000 && instr_i[FUNCT7_MSB:FUNCT7_MSB - 7 + 1] == 7'b0000000) begin
					alu_op_o = ALU_ADD;
				end
				// SUB
				else if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b000 && instr_i[FUNCT7_MSB:FUNCT7_MSB - 7 + 1] == 7'b0100000) begin
					alu_op_o = ALU_SUB;
				end
				// XOR
				else if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b100 && instr_i[FUNCT7_MSB:FUNCT7_MSB - 7 + 1] == 7'b0000000) begin
					alu_op_o = ALU_XOR;
				end
				// SRA
				else if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b101 && instr_i[FUNCT7_MSB:FUNCT7_MSB - 7 + 1] == 7'b0100000) begin
					alu_op_o = ALU_SRA;
				end
				// DEFAULT TO ADD NO-OP
				else begin
					alu_op_o = ALU_ADD;
				end
			end
			I_TYPE: begin
				// ADDI
				if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b000) begin
					alu_op_o = ALU_ADD;
				end
				// ANDI
				else if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b111) begin
					alu_op_o = ALU_AND;
				end
				// DEFAULT TO ADD NO-OP
				else begin
					alu_op_o = ALU_ADD;
				end
			end
			// LW
			L_TYPE: begin
				if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b010) begin
					alu_op_o = ALU_ADD;
				end
				// DEFAULT TO ADD NO-OP
				else begin
					alu_op_o = ALU_ADD;
				end
			end
			// SW
			S_TYPE: begin
				if (instr_i[FUNCT3_MSB: FUNCT3_MSB - 3 + 1] == 3'b010) begin
					alu_op_o = ALU_ADD;
				end
				// DEFAULT TO ADD NO-OP
				else begin
					alu_op_o = ALU_ADD;
				end
			end
			default: begin
				alu_op_o = 0;
			end
		endcase
	end
	
	
	
endmodule
