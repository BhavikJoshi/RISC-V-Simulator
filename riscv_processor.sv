module riscv_processor(clk);

	// ***** Parameters *****
	// Instructions
	localparam PC_SIZE = 32;
	localparam INSTR_SIZE = 32;
	localparam WORD_SIZE = 32;
	localparam MAX_IMEM_ROWS = 4096;
	
	// Registers
	localparam NUM_A_REGS = 32; // MUST BE 32!
	localparam NUM_P_REGS = 64;
	
	// Control Signals
	localparam CONTR_SIG_SIZE = 5;
	localparam CONTR_VALID_INDEX = 0;
	localparam CONTR_REGWRITE_INDEX = 1;
	localparam CONTR_ALUSRC_INDEX = 2;
	localparam CONTR_MEMRE_INDEX = 3;
	localparam CONTR_MEMWR_INDEX = 4;
	localparam ALU_OP_SIZE = 4;
	localparam ALU_ADD = 4'b0010;
	localparam ALU_SUB = 4'b0110;
	localparam ALU_AND = 4'b0000;
	localparam ALU_XOR = 4'b1000;
	localparam ALU_SRA = 4'b1001;
	
	// OoO Parameters
	localparam ROB_SIZE = 16;
	localparam NUM_RS_ROWS = 16;
	localparam MEM_SIZE = 1024;
	
	// ***** Var Declarations *****
	output reg clk;
	// IF
	reg [PC_SIZE-1:0] pc;
	wire [INSTR_SIZE-1:0] instr0;
	wire [INSTR_SIZE-1:0] instr1;
	wire end_of_instructions, if0_done, if1_done;
	
	// IF/DE
	reg [PC_SIZE-1:0] IF_DE_pc0;
	reg [PC_SIZE-1:0] IF_DE_pc1;
	reg [INSTR_SIZE-1:0] IF_DE_instruction0;
	reg [INSTR_SIZE-1:0] IF_DE_instruction1;
	
	// DE
	wire [$clog2(NUM_A_REGS)-1:0] rd0, rd1, rs10, rs11, rs20, rs21;
	wire [WORD_SIZE-1:0] imm0, imm1;
	wire [ALU_OP_SIZE-1:0] alu_op0, alu_op1;
	wire [CONTR_SIG_SIZE-1:0] contr0, contr1;
	
	// DE/R
	reg [PC_SIZE-1:0] DE_R_pc0;
	reg [PC_SIZE-1:0] DE_R_pc1;
	reg [WORD_SIZE-1:0] DE_R_imm0, DE_R_imm1;
	reg [ALU_OP_SIZE-1:0] DE_R_alu_op0, DE_R_alu_op1;
	reg [CONTR_SIG_SIZE-1:0] DE_R_contr0, DE_R_contr1;
	
	// R
	wire [$clog2(NUM_P_REGS)-1:0] old_dest0, old_dest1, new_dest0, new_dest1, p_rs10, p_rs11, p_rs20, p_rs21;
	wire rename_stage_pregs_full;
	wire [WORD_SIZE-1:0] read_reg0_val;
	wire [WORD_SIZE-1:0] read_reg1_val;
	wire [WORD_SIZE-1:0] read_reg2_val;
	wire [WORD_SIZE-1:0] read_reg3_val;
	
	// DI <--> ROB
	wire instr0_completed;
	wire instr1_completed;
	wire instr2_completed;
	wire [$clog2(ROB_SIZE)-1:0] completed_index_instr0;
	wire [$clog2(ROB_SIZE)-1:0] completed_index_instr1;
	wire [$clog2(ROB_SIZE)-1:0] completed_index_instr2;
	wire [PC_SIZE-1:0] completed_pc_instr0;
	wire [PC_SIZE-1:0] completed_pc_instr1;
	wire [PC_SIZE-1:0] completed_pc_instr2;
	wire [WORD_SIZE-1:0] completed_val_instr0;
	wire [WORD_SIZE-1:0] completed_val_instr1;
	wire [WORD_SIZE-1:0] completed_val_instr2;
	
	wire [$clog2(ROB_SIZE)-1:0] rob_next_index0;
	wire [$clog2(ROB_SIZE)-1:0] rob_next_index1;
	wire retire_instr0;
	wire retire_instr1;
	wire [$clog2(NUM_P_REGS)-1:0] retire_dest0;
	wire [$clog2(NUM_P_REGS)-1:0] retire_dest1;
	wire [$clog2(NUM_P_REGS)-1:0] retire_old_dest0;
	wire [$clog2(NUM_P_REGS)-1:0] retire_old_dest1;
	wire [WORD_SIZE-1:0] retire_val0;
	wire [WORD_SIZE-1:0] retire_val1;
	
	wire rob_fwd_table_ready [0:NUM_P_REGS-1];
	wire [WORD_SIZE-1:0] rob_fwd_table_val [0:NUM_P_REGS-1];
	
	// Intialize registers
	initial begin
		clk = 0;
		pc = 0;
		IF_DE_instruction0 = 0; IF_DE_instruction1 = 0;
		IF_DE_pc0 = 0; IF_DE_pc1 = 0;
		DE_R_pc0 = 0; DE_R_pc1 = 0;
		DE_R_imm0 = 0; DE_R_imm1 = 0;
		DE_R_alu_op0 = 0; DE_R_alu_op1 = 0;
	end
	
	// Simulate clock cycle
	always begin
		#5	clk = ~clk;
	end
	
	
	// Check for end of instruction
	always begin
		#5000 $stop();
	end
	
	// Update PC
	always @ (posedge clk) begin
		pc <= pc + 8;
	end
	
	// IF STAGE
	instruction_reader #(PC_SIZE, INSTR_SIZE, MAX_IMEM_ROWS) IF0 (.pc_i(pc), .instr_o(instr0), .done_o(if0_done));
	instruction_reader #(PC_SIZE, INSTR_SIZE, MAX_IMEM_ROWS) IF1 (.pc_i(pc+4), .instr_o(instr1), .done_o(if1_done));
	assign end_of_instructions = if0_done && if1_done;
	
	// IF/DE
	always @ (posedge clk) begin
		IF_DE_pc0 <= pc;
		IF_DE_pc1 <= pc+4;
		IF_DE_instruction0 <= instr0;
		IF_DE_instruction1 <= instr1;
	end
	
	// DE STAGE
	decode_stage #(INSTR_SIZE, WORD_SIZE, NUM_A_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND, ALU_XOR, ALU_SRA, CONTR_SIG_SIZE, CONTR_VALID_INDEX, CONTR_REGWRITE_INDEX, CONTR_ALUSRC_INDEX,
						CONTR_MEMRE_INDEX, CONTR_MEMWR_INDEX)
						DE0 (.instr_i(IF_DE_instruction0), .rd_o(rd0), .rs1_o(rs10), .rs2_o(rs20), .imm_o(imm0), .alu_op_o(alu_op0), .control_o(contr0));
	decode_stage #(INSTR_SIZE, WORD_SIZE, NUM_A_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND, ALU_XOR, ALU_SRA, CONTR_SIG_SIZE, CONTR_VALID_INDEX, CONTR_REGWRITE_INDEX, CONTR_ALUSRC_INDEX,
						CONTR_MEMRE_INDEX, CONTR_MEMWR_INDEX)
						DE1 (.instr_i(IF_DE_instruction1), .rd_o(rd1), .rs1_o(rs11), .rs2_o(rs21), .imm_o(imm1), .alu_op_o(alu_op1), .control_o(contr1));

	// DE/R (don't need to store A-reg values, P-reg values are given by rename stage)
	always @ (posedge clk) begin
		DE_R_pc0 <= IF_DE_pc0;
		DE_R_pc1 <= IF_DE_pc1;
		DE_R_imm0 <= imm0;
		DE_R_imm1 <= imm1;
		DE_R_alu_op0 <= alu_op0;
		DE_R_alu_op1 <= alu_op1;
		DE_R_contr0 <= contr0;
		DE_R_contr1 <= contr1;
	end
	
	// DE/R + R STAGE
	// RAT is sequential, so takes DEST and SRC registers directly from DE and renames on the next tick
	register_renamer #(NUM_A_REGS, NUM_P_REGS) R0 (.clk_i(clk), .en_free_reg0_i(retire_instr0), .en_free_reg1_i(retire_instr1), .free_reg0_i(retire_old_dest0), .free_reg1_i(retire_old_dest1), .en_new_dest0_i(contr0[CONTR_VALID_INDEX]),
							.en_new_dest1_i(contr1[CONTR_VALID_INDEX]), .assign_dest0_i(rd0), .assign_dest1_i(rd1), .get_src10_i(rs10), .get_src11_i(rs11), .get_src20_i(rs20),
							.get_src21_i(rs21), .old_dest0_o(old_dest0), .old_dest1_o(old_dest1), .p_dest0_o(new_dest0), .p_dest1_o(new_dest1), .p_src10_o(p_rs10), .p_src11_o(p_rs11),
							.p_src20_o(p_rs20), .p_src21_o(p_rs21), .no_pregs_left_o(rename_stage_pregs_full));
							
	register_file #(NUM_P_REGS, WORD_SIZE) RF (.clk_i(clk), .reg_write0_i(retire_instr0), .reg_write1_i(retire_instr1), .dest0_i(retire_dest0), .dest1_i(retire_dest1), .word0(retire_val0), .word1(retire_val1), .read_reg0_i(p_rs10), .read_reg1_i(p_rs11),
						.read_reg2_i(p_rs20), .read_reg3_i(p_rs21), .val_reg0_o(read_reg0_val), .val_reg1_o(read_reg1_val), .val_reg2_o(read_reg2_val), .val_reg3_o(read_reg3_val));
			
	// R/Di STAGE
	always @ (posedge clk) begin
	
	end
			
	dispatch_issue #(PC_SIZE, WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND, ALU_XOR , ALU_SRA, CONTR_SIG_SIZE, CONTR_VALID_INDEX, CONTR_REGWRITE_INDEX, CONTR_ALUSRC_INDEX,
						  CONTR_MEMRE_INDEX, CONTR_MEMWR_INDEX, ROB_SIZE, NUM_RS_ROWS, MEM_SIZE)
						  DI0 (.clk_i(clk), .new_row0_i(DE_R_contr0[CONTR_VALID_INDEX]), .new_row1_i(DE_R_contr1[CONTR_VALID_INDEX]), .dest0_i(new_dest0), .dest1_i(new_dest1), . rs10_i(p_rs10),
						  .rs11_i(p_rs11), .rs10_val_i(read_reg0_val), .rs11_val_i(read_reg1_val), .rs20_i(p_rs10), .rs21_i(p_rs21), .rs20_val_i(read_reg2_val), .rs21_val_i(read_reg3_val),
						  .imm0_i(DE_R_imm0), .imm1_i(DE_R_imm1), .contr0_i(DE_R_contr0), .contr1_i(DE_R_contr1),. alu_op0_i(DE_R_alu_op0), .alu_op1_i(DE_R_alu_op1), .rob_index0_i(rob_next_index0),
						  .rob_index1_i(rob_next_index1), .pc0_i(DE_R_pc0), .pc1_i(DE_R_pc1), .rob_fwd_table_ready_i(rob_fwd_table_ready), .rob_fwd_table_val_i(rob_fwd_table_val), .en_complete_instr0_o(instr0_completed),
						  .en_complete_instr1_o(instr1_completed), .en_complete_instr2_o(instr2_completed), .index_complete_instr0_o(completed_index_instr0), .index_complete_instr1_o(completed_index_instr1),
						  .index_complete_instr2_o(completed_index_instr2), .pc_complete_instr0_o(completed_pc_instr0),.pc_complete_instr1_o(completed_pc_instr1), .pc_complete_instr2_o(completed_pc_instr2),
						  .val_complete_instr0_o(completed_val_instr0), .val_complete_instr1_o(completed_val_instr1), .val_complete_instr2_o(completed_val_instr2), .rs_full_o());
	
	 reorder_buffer #(PC_SIZE, WORD_SIZE, NUM_P_REGS, CONTR_SIG_SIZE, CONTR_VALID_INDEX, CONTR_REGWRITE_INDEX, CONTR_ALUSRC_INDEX, CONTR_MEMRE_INDEX, CONTR_MEMWR_INDEX, ROB_SIZE)
						 ROB0 (.clk_i(clk), .en_reserve_instr0_i(DE_R_contr0[CONTR_VALID_INDEX]), . en_reserve_instr1_i(DE_R_contr1[CONTR_VALID_INDEX]), .instr0_dest_i(new_dest0),
						 .instr1_dest_i(new_dest1), .instr0_old_dest_i(old_dest0), .instr1_old_dest_i(old_dest1), .instr0_contr_i(DE_R_contr0), .instr1_contr_i(DE_R_contr1),
						 .instr0_pc_i(DE_R_pc0), .instr1_pc_i(DE_R_pc1), .en_complete_instr0_i(instr0_completed), .en_complete_instr1_i(instr1_completed), .en_complete_instr2_i(instr2_completed),
						 .complete_indx0_i(completed_index_instr0), .complete_indx1_i(completed_index_instr1), .complete_indx2_i(completed_index_instr2), .complete_pc0_i(completed_pc_instr0),
						 .complete_pc1_i(completed_pc_instr1), .complete_pc2_i(completed_pc_instr2), .complete_val0_i(completed_val_instr0), .complete_val1_i(completed_val_instr1), .complete_val2_i(completed_val_instr2),
						 .rob_fwd_table_ready_o(rob_fwd_table_ready), .rob_fwd_table_val_o(rob_fwd_table_val), .en_retire_dest0_o(retire_instr0), .en_retire_dest1_o(retire_instr1), .retire_dest0_o(retire_dest0), .retire_dest1_o(retire_dest1), .retire_old_dest0_o(retire_old_dest0),
						 .retire_old_dest1_o(retire_old_dest1), .retire_val0_o(retire_val0), .retire_val1_o(retire_val1), .tail_indx_0(rob_next_index0), .tail_indx_1(rob_next_index1), .rob_full_o());
	
	
endmodule