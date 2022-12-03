module dispatch_issue #(parameter WORD_SIZE = 32, NUM_A_REGS = 32, NUM_P_REGS = 64, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000,
								ALU_XOR = 4'b1000, ALU_SRA = 4'b1001, CONTR_SIG_SIZE = 5, CONTR_VALID_INDEX = 0, CONTR_REGWRITE_INDEX = 1, CONTR_ALUSRC_INDEX = 2,
								CONTR_MEMRE_INDEX = 3, CONTR_MEMWR_INDEX = 4, ROB_SIZE = 64)
	(
		input clk_i,
		input new_row0_i;
		input new_row1_i;
		input [$clog2(NUMP_P_REGS)-1:0] dest0_i, 
		input [$clog2(NUMP_P_REGS)-1:0] dest1_i,
		input [$clog2(NUMP_P_REGS)-1:0] rs10_i,
		input [$clog2(NUMP_P_REGS)-1:0] rs11_i,
		input [WORD_SIZE-1:0] rs10_val_i,
		input [WORD_SIZE-1:0] rs11_val_i,
		input [$clog2(NUMP_P_REGS)-1:0] rs20_i,
		input [$clog2(NUMP_P_REGS)-1:0] rs21_i,
		input [WORD_SIZE-1:0] rs20_val_i,
		input [WORD_SIZE-1:0] rs21_val_i,
		input [WORD_SIZE-1:0] imm0_i,
		input [WORD_SIZE-1:0] imm1_i,
		input [CONTR_SIG_SIZE-1:0] contr0_i,
		input [CONTR_SIG_SIZE-1:0] contr1_i,
		input [ALU_OP_SIZE-1:0] alu_op0_i,
		input [ALU_OP_SIZE-1:0] alu_op1_i,
		input [$clog2(ROB_SIZE)-1:0] rob_index0_i,
		input [$clog2(ROB_SIZE)-1:0] rob_index1_i,
		input en_retire_fwd0_i,
		input en_retire_fwd1_i,
		input [$clog2(NUM_P_REGS)-1:0] retire_fwd_dest0_i,
		input [$clog2(NUM_P_REGS)-1:0] retire_fwd_dest1_i,
		input [WORD_SIZE-1:0] retire_fwd_val0_i, 
		input [WORD_SIZE-1:0] retire_fwd_val1_i,
		output en_complete_instr0_o,
		output en_complete_instr1_o,
		output en_complete_instr2_o,
		output [$clog2(ROB_SIZE)-1:0] index_complete_instr0_o,
		output [$clog2(ROB_SIZE)-1:0] index_complete_instr1_o,
		output [$clog2(ROB_SIZE)-1:0] index_complete_instr2_o,
		output [WORD_SIZE-1:0] val_complete_instr0_o,
		output [WORD_SIZE-1:0] val_complete_instr1_o,
		output [WORD_SIZE-1:0] val_complete_instr2_o,
		output rs_full_o
	);

	localparam NUM_RS_ROWS = 64;
	localparam NUM_ALU_FUS = 2;
	localparam NUM_MEM_FUS = 1;
	localparam FU_ALU = 0;
	localparam FU_MEM = 1;
	
	typedef struct packed {
		reg used;
		reg [$clog2(NUM_P_REGS)-1:0] dest;
		reg [$clog2(NUM_P_REGS)-1:0] rs1;
		reg [WORD_SIZE-1:0] rs1_val;
		reg [$clog2(NUM_P_REGS)-1:0] rs2;
		reg [WORD_SIZE-1:0] rs2_val;
		reg [WORD_SIZE-1:0] imm;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(ROB_SIZE)-1:0] rob_index;
		reg fu_type;
	} rs_entry;
	
	typedef struct packed {
		reg used;
		reg done;
		reg [$clog2(NUM_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] data0;
		reg [WORD_SIZE-1:0] data1;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(ROB_SIZE)-1:0] rob_index;
		wire [WORD_SIZE-1:0] result;
	} fu_issue;
	
	typedef rs_entry rs [0:NUM_RS_ROWS-1];
	
	typedef fu_issue alu_issue[0:NUM_ALU_FUS-1];
	typedef fu_issue mem_issue;
	
	reg src_ready [0:NUM_P_REGS];
	reg fu_ready [0:NUM_ALU_FS + NUM_MEM_FUS-1];
	
	initial begin
		integer i;
		for (i = 0 ; i < NUM_RS_ROWS; i++) begin
			rs[i].used = 0;
		end
		for (i = 0 ; i < NUM_P_REGS; i++) begin
			src_ready[i] = 1'b1;
		end
		for (i = 0 ; i < NUM_ALU_FUS + NUM_MEM_FUS; i++) begin
			fu_ready[i] = 1'b1;
		end
		for (i = 0 ; i < NUM_ALU_FUS; i++) begin
			alu_issue[i].used = 1'b0;
			alu_issue[i].done = 1'b0;
		end
		mem_issue.used = 1'b0;
		mem_issue.done = 1'b0;
	end
	
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU0 (.alu_op_i(alu_issue[0].alu_op), alU_data0_i(alu_issue[0].data0), alu_data1_i(alu_issue[0].data1), result_o(alu_issue[0].result), zero_o());
				 
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU1 (.alu_op_i(alu_issue[1].alu_op), alU_data0_i(alu_issue[1].data0), alu_data1_i(alu_issue[1].data1), result_o(alu_issue[1].result), zero_o());
	
	// Assign outputs to ROB
	assign en_done_instr0_o = alu_issue[0].used & alu_issue[0].done;
	assign index_done_instr0_o = alu_issue[0].rob_index;
	assign en_done_instr1_o = alu_issue[1].used & alu_issue[1].done;
	assign index_done_instr1_o = alu_issue[1].rob_index;
	// TODO: mem done instructions
	// TODO: RS full output
	
	always @ (posedge clk) begin
		integer i;
		integer a;
		// Add instruction 0
		if (new_row0_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				if (rs[i].used == 1'b0) begin
					// Add to unused row
					rs[i].used = 1'b1;
					rs[i].dest = dest0_i;
					rs[i].rs1 = rs10_i;
					rs[i].rs1_val = rs10_val_i;
					rs[i].rs2 = rs20_i;
					rs[i].rs2_val = rs20_val_i;
					rs[i].imm = imm0_i;
					rs[i].contr = contr0_i;
					rs[i].alu_op = alu_op0_i;
					rs[i].rob_index = rob_index0_i;
					// Mark destination as not ready
					if (src_ready[rs[i].dest] == 1'b1) begin
						src_ready[rs[i].dest] = 1'b0;
					end
					else begin
						$display("Error: new RS entry destination already marked as not ready");
					end
					break;
				end
			end
		end
		// Add instruction 1
		if (new_row1_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				if (rs[i].used == 1'b0) begin
					// Add to unused row
					rs[i].used = 1'b1;
					rs[i].dest = dest1_i;
					rs[i].rs1 = rs11_i;
					rs[i].rs1_val = rs11_val_i;
					rs[i].rs2 = rs21_i;
					rs[i].rs2_val = rs21_val_i;
					rs[i].imm = imm1_i;
					rs[i].contr = contr1_i;
					rs[i].alu_op = alu_op1_i;
					rs[i].rob_index = rob_index1_i;
					// Mark destination as not ready
					if (src_ready[rs[i].dest] == 1'b1) begin
						src_ready[rs[i].dest] = 1'b0;
					end
					else begin
						$display("Error: new RS entry destination already marked as not ready");
					end
					break;
				end
			end
		end
		
		// FORWARD FROM ROB RETIRE
		if (en_retire_fwd0_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				// If RS entry is valid
				if (rs[i].used == 1'b1) begin
					// Forward RS1
					if (rs[i].rs1 == retire_fwd_dest0_i) begin
						rs[i].rs1_val = retire_fwd_val0_i;
					end
					// Forward RS2
					if (rs[i].rs2 == retire_fwd_dest0_i) begin
						rs[i].rs2_val = retire_fwd_val0_i;
					end
				end
			end
		end
		if (en_retire_fwd1_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				// If RS entry is valid
				if (rs[i].used == 1'b1) begin
					// Forward RS1
					if (rs[i].rs1 == retire_fwd_dest1_i) begin
						rs[i].rs1_val = retire_fwd_val1_i;
					end
					// Forward RS2
					if (rs[i].rs2 == retire_fwd_dest1_i) begin
						rs[i].rs2_val = retire_fwd_val1_i;
					end
				end
			end
		end
		
		// Free FUs and forward value if needed
		for (a = 0; a < NUM_ALU_FUS; a++) begin
			// If the ALU was used last clock cycle and is complete this clock cycle
			if (alu_issue[a].used == 1'b1 && alu_issue[a].done == 1'b1) begin
				// Forward RS1 and RS2 values to RS from ALU FU Dest Values
				for (i = 0; i < NUM_RS_ROWS; i++) begin
					// If RS entry is valid
					if (rs[i].used == 1'b1) begin
						// Forward RS1
						if (rs[i].rs1 == alu_issue[a].dest) begin
							rs[i].rs1_val = alu_issue[a].result;
						end
						// Forward RS2
						if (rs[i].rs2 == alu_issue[a].dest) begin
							rs[i].rs2_val = alu_issue[a].result;
						end
					end
				end
				// Mark FUs and SRCs as ready
				alu_issue[a].used = 1'b0;
				alu_issue[a].done = 1'b0;
				src_ready[alu_issue[a].dest] = 1'b1;
				fu_ready[a] = 1'b1;
			end
		end
		// TODO: forward from MEM FUs and mark then as unready


		// Schedule ready instructions from RS to FUs, Mark FUs as not ready, remove lines from RS
		for (i = 0; i < NUM_RS_ROW; i++) begin
			// If valid entry
			if (rs[i].used == 1'b1) begin
				// If RS1 ready and (SRC is IMM or RS2 is ready)
				if (src_ready[rs[i].rs1] == 1'b1 && (rs[i].contr[CONTR_ALUSRC_INDEX] == 1'b1 || src_ready[rs[i].rs2] == 1'b1)) begin 
					// If is an ALU instructions
					if (rs[i].fu_type == FU_ALU) begin
						// If an FU is ready, schedule it
						for (a = 0; a < NUM_ALU_FUS; a++) begin
							// FU[a] is ready
							if (fu_ready[a] == 1'b1 && alu_issue[a].used == 1'b0) begin
								// Schedule instruction
								fu_ready[a] = 1'b0;
								alu_issue[0].used = 1'b1;
								alu_issue[0].done = 1'b0;
								alu_issue[0].dest = rs[i].dest;
								alu_issue[0].data0 = rs[i].rs1_val;
								alu_issue[0].data1 = rs[i].contr[CONTR_ALUSRC_INDEX] == 1'b1 ? rs[i].imm : rs[i].rs2_val;
								alu_issue[0].contr = rs[i].contr;
								alu_issue[0].alu_op = rs[i].alu_op;
								alu_issue[0].rob_index = rs[i].rob_index;
								// Remove instruction from RS
								rs[i].used = 1'b0;
								break; // Only schedule in one FU
							end
						end
					end
					// TODO: If it is a MEM instruction
					else if (rs[i].fu_type == FU_MEM) begin
						//
					end
				end // SRCs not ready
			end // RS row not used
		end
		
		// If ALU FUs are used and not ready, mark as ready since are now ready in the same clock cycle
		for (a = 0; a < NUM_ALU_FUS; a++) begin
			if (alu_issue[a].used == 1'b1 && alu_issue[a].done == 1'b0) begin
				alu_issue[a].done = 1'b1;
			end
		end
	end
	

endmodule