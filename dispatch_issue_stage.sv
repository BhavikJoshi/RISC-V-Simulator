module dispatch_issue #(parameter PC_SIZE = 32, WORD_SIZE = 32, NUM_P_REGS = 64, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000,
								ALU_XOR = 4'b1000, ALU_SRA = 4'b1001, CONTR_SIG_SIZE = 5, CONTR_VALID_INDEX = 0, CONTR_REGWRITE_INDEX = 1, CONTR_ALUSRC_INDEX = 2,
								CONTR_MEMRE_INDEX = 3, CONTR_MEMWR_INDEX = 4, ROB_SIZE = 16, NUM_RS_ROWS = 16, MEM_SIZE = 1024)
	(
		input clk_i,
		input new_row0_i,
		input new_row1_i,
		input [$clog2(NUM_P_REGS)-1:0] dest0_i, 
		input [$clog2(NUM_P_REGS)-1:0] dest1_i,
		input [$clog2(NUM_P_REGS)-1:0] rs10_i,
		input [$clog2(NUM_P_REGS)-1:0] rs11_i,
		input [WORD_SIZE-1:0] rs10_val_i,
		input [WORD_SIZE-1:0] rs11_val_i,
		input [$clog2(NUM_P_REGS)-1:0] rs20_i,
		input [$clog2(NUM_P_REGS)-1:0] rs21_i,
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
		input [PC_SIZE-1:0] pc0_i,
		input [PC_SIZE-1:0] pc1_i,
		input rob_fwd_table_ready_i [0:NUM_P_REGS-1],
		input [WORD_SIZE-1:0] rob_fwd_table_val_i [0:NUM_P_REGS-1],
		output reg en_complete_instr0_o,
		output reg en_complete_instr1_o, 
		output reg en_complete_instr2_o,
		output reg [$clog2(ROB_SIZE)-1:0] index_complete_instr0_o,
		output reg [$clog2(ROB_SIZE)-1:0] index_complete_instr1_o,
		output reg [$clog2(ROB_SIZE)-1:0] index_complete_instr2_o,
		output reg [PC_SIZE-1:0] pc_complete_instr0_o,
		output reg [PC_SIZE-1:0] pc_complete_instr1_o,
		output reg [PC_SIZE-1:0] pc_complete_instr2_o,
		output reg [WORD_SIZE-1:0] val_complete_instr0_o,
		output reg [WORD_SIZE-1:0] val_complete_instr1_o,
		output reg [WORD_SIZE-1:0] val_complete_instr2_o,
		output rs_full_o
	);

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
		reg [PC_SIZE-1:0] pc;
		reg fu_type;
	} rs_entry_s;
	
	typedef struct packed {
		reg used;
		reg done;
		reg [$clog2(NUM_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] data0;
		reg [WORD_SIZE-1:0] data1;
		reg [WORD_SIZE-1:0] data2;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(ROB_SIZE)-1:0] rob_index;
		reg [PC_SIZE-1:0] pc;
	} fu_issue_s;
	
	rs_entry_s rs [0:NUM_RS_ROWS-1];
	
	fu_issue_s alu_issue[0:NUM_ALU_FUS-1];
	fu_issue_s mem_issue;
	
	reg [WORD_SIZE-1:0] fu_result [0:NUM_ALU_FUS + NUM_MEM_FUS-1];
	
	reg src_ready [0:NUM_P_REGS-1];
	reg fu_ready [0:NUM_ALU_FUS + NUM_MEM_FUS-1];
	integer num_free_rows;
	
	reg [$clog2(NUM_P_REGS)-1:0] complete_dest0;
	reg [$clog2(NUM_P_REGS)-1:0] complete_dest1;
	reg [$clog2(NUM_P_REGS)-1:0] complete_dest2;
	reg [CONTR_SIG_SIZE-1:0] complete_contr0;
	reg [CONTR_SIG_SIZE-1:0] complete_contr1;
	reg [CONTR_SIG_SIZE-1:0] complete_contr2;
	
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
				 ALU_XOR, ALU_SRA) ALU0 (.alu_op_i(alu_issue[0].alu_op), .alu_data0_i(alu_issue[0].data0), .alu_data1_i(alu_issue[0].data1), .result_o(fu_result[0]), .zero_o());
				 
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU1 (.alu_op_i(alu_issue[1].alu_op), .alu_data0_i(alu_issue[1].data0), .alu_data1_i(alu_issue[1].data1),. result_o(fu_result[1]), .zero_o());
				 
	memory #(WORD_SIZE, MEM_SIZE) MEM0 (.en_mem_i(mem_issue.used), .mem_read_i(mem_issue.contr[CONTR_MEMRE_INDEX]), .mem_write_i(mem_issue.contr[CONTR_MEMWR_INDEX]), .addr_base_i(mem_issue.data0), .addr_offset_i(mem_issue.data1), .val_i(mem_issue.data2), .val_o(fu_result[2]));
	
	// Output RS full if less than two free rows
	assign rs_full_o = num_free_rows < 2;

	// Count empty rows
	always @ (*) begin
		integer i;
		num_free_rows = 0;
		for (i = 0; i < NUM_RS_ROWS; i++) begin
			num_free_rows += rs[i].used;
		end
	end
	
	always @ (posedge clk_i) begin
		integer i;
		integer a;
		
		// Free FUs and forward value if needed
		for (a = 0; a < NUM_ALU_FUS; a++) begin
			// If the ALU was used last clock cycle and is complete this clock cycle
			if (alu_issue[a].used == 1'b1 && alu_issue[a].done == 1'b1) begin
				// Forward RS1 and RS2 values to RS from ALU FU Dest Values
				for (i = 0; i < NUM_RS_ROWS; i++) begin
					// If RS entry is valid
					if (rs[i].used == 1'b1) begin
						// Forward RS1
						if (rs[i].rs1 == alu_issue[a].dest && alu_issue[a].dest != 0) begin
							rs[i].rs1_val = fu_result[a];
						end
						// Forward RS2
						if (rs[i].rs2 == alu_issue[a].dest && alu_issue[a].dest != 0) begin
							rs[i].rs2_val = fu_result[a];
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
		if (mem_issue.used == 1'b1 && mem_issue.done == 1'b1) begin
				// Forward RS1 and RS2 values to RS from Mem FU Dest Values
				for (i = 0; i < NUM_RS_ROWS; i++) begin
					// If RS entry is valid
					if (rs[i].used == 1'b1) begin
						// Forward RS1
						if (rs[i].rs1 == mem_issue.dest && mem_issue.dest != 0) begin
							rs[i].rs1_val = fu_result[2];
						end
						// Forward RS2
						if (rs[i].rs2 == mem_issue.dest && mem_issue.dest != 0) begin
							rs[i].rs2_val = fu_result[2];
						end
					end
				end
				// Mark FUs and SRCs as ready
				mem_issue.used = 1'b0;
				mem_issue.done = 1'b0;
				src_ready[mem_issue.dest] = 1'b1;
				fu_ready[2] = 1'b1;
			end
		
		// Schedule ready instructions from RS to FUs, Mark FUs as not ready, remove lines from RS
		for (i = 0; i < NUM_RS_ROWS; i++) begin
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
								alu_issue[a].used = 1'b1;
								alu_issue[a].done = 1'b0;
								alu_issue[a].dest = rs[i].dest;
								alu_issue[a].data0 = rs[i].rs1_val;
								alu_issue[a].data1 = rs[i].contr[CONTR_ALUSRC_INDEX] == 1'b1 ? rs[i].imm : rs[i].rs2_val;
								alu_issue[a].contr = rs[i].contr;
								alu_issue[a].alu_op = rs[i].alu_op;
								alu_issue[a].rob_index = rs[i].rob_index;
								alu_issue[a].pc = rs[i].pc;
								// Remove instruction from RS
								rs[i].used = 1'b0;
								break; // Only schedule in one FU
							end
						end
					end
					// If it is a MEM instruction
					else if (rs[i].fu_type == FU_MEM) begin
						if (fu_ready[2] == 1'b1 && mem_issue.used == 1'b0) begin
							// Schedule instruction
							fu_ready[2] = 1'b0;
							mem_issue.done = 1'b0;
							mem_issue.dest = rs[i].dest;
							mem_issue.data0 = rs[i].rs1_val;
							mem_issue.data1 = rs[i].imm;
							mem_issue.data2 = rs[i].rs2_val;
							mem_issue.contr = rs[i].contr;
							mem_issue.alu_op = rs[i].alu_op;
							mem_issue.rob_index = rs[i].rob_index;
							mem_issue.pc = rs[i].pc;
							mem_issue.used = 1'b1;
							// Remove instruction from RS
							rs[i].used = 1'b0;
						end
					end
				end // SRCs not ready
			end // RS row not used
		end
		
		// Add instructions to RS
		if (new_row0_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				if (rs[i].used == 1'b0) begin
					// Add to unused row
					rs[i].used = 1'b1;
					rs[i].dest = dest0_i;
					rs[i].rs1 = rs10_i;
					rs[i].rs2 = rs20_i;
					// Forward sources from ROB if they are currently in complete
					rs[i].rs1_val = rs10_i != 0 && rob_fwd_table_ready_i[rs10_i] == 1'b1 ? rob_fwd_table_val_i[rs10_i] : rs10_val_i;
					rs[i].rs2_val = rs20_i != 0 && rob_fwd_table_ready_i[rs20_i] == 1'b1 ? rob_fwd_table_val_i[rs20_i] : rs20_val_i;
					// Forward sources from previous cycle issue complete since ROB fwd table is currently updating with new value
					if (en_complete_instr0_o == 1'b1 && complete_contr0[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest0) begin
							rs[i].rs1_val = val_complete_instr0_o;
						end
						if (rs[i].rs2 == complete_dest0) begin
							rs[i].rs2_val = val_complete_instr0_o;
						end
					end
					if (en_complete_instr1_o == 1'b1 && complete_contr1[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest1) begin
							rs[i].rs1_val = val_complete_instr1_o;
						end
						if (rs[i].rs2 == complete_dest1) begin
							rs[i].rs2_val = val_complete_instr1_o;
						end
					end
					if (en_complete_instr2_o == 1'b1 && complete_contr2[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest2) begin
							rs[i].rs1_val = val_complete_instr2_o;
						end
						if (rs[i].rs2 == complete_dest2) begin
							rs[i].rs2_val = val_complete_instr2_o;
						end
					end
					rs[i].imm = imm0_i;
					rs[i].contr = contr0_i;
					rs[i].alu_op = alu_op0_i;
					rs[i].rob_index = rob_index0_i;
					rs[i].pc = pc0_i;
					rs[i].fu_type = contr0_i[CONTR_MEMRE_INDEX] | contr0_i[CONTR_MEMWR_INDEX];
					// Mark destination as not ready
					if (src_ready[rs[i].dest] == 1'b1 && rs[i].dest != 0) begin
						src_ready[rs[i].dest] = 1'b0;
					end
					else begin
						$display("Error: new RS entry destination already marked as not ready");
					end
					break;
				end
			end
		end
		if (new_row1_i) begin
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				if (rs[i].used == 1'b0) begin
					// Add to unused row
					rs[i].used = 1'b1;
					rs[i].dest = dest1_i;
					rs[i].rs1 = rs11_i;
					rs[i].rs2 = rs21_i;
					// Forward sources from ROB if they are currently in complete
					rs[i].rs1_val = rs11_i != 0 && rob_fwd_table_ready_i[rs11_i] == 1'b1 ? rob_fwd_table_val_i[rs11_i] : rs11_val_i;
					rs[i].rs2_val = rs21_i != 0 && rob_fwd_table_ready_i[rs21_i] == 1'b1 ? rob_fwd_table_val_i[rs21_i] : rs21_val_i;
					// Forward sources from previous cycle issue complete since ROB fwd table is currently updating with new value
					if (en_complete_instr0_o == 1'b1 && complete_contr0[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest0) begin
							rs[i].rs1_val = val_complete_instr0_o;
						end
						if (rs[i].rs2 == complete_dest0) begin
							rs[i].rs2_val = val_complete_instr0_o;
						end
					end
					if (en_complete_instr1_o == 1'b1 && complete_contr1[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest1) begin
							rs[i].rs1_val = val_complete_instr1_o;
						end
						if (rs[i].rs2 == complete_dest1) begin
							rs[i].rs2_val = val_complete_instr1_o;
						end
					end
					if (en_complete_instr2_o == 1'b1 && complete_contr2[CONTR_REGWRITE_INDEX]) begin
						if (rs[i].rs1 == complete_dest2) begin
							rs[i].rs1_val = val_complete_instr2_o;
						end
						if (rs[i].rs2 == complete_dest2) begin
							rs[i].rs2_val = val_complete_instr2_o;
						end
					end
					rs[i].imm = imm1_i;
					rs[i].contr = contr1_i;
					rs[i].alu_op = alu_op1_i;
					rs[i].rob_index = rob_index1_i;
					rs[i].pc = pc1_i;
					rs[i].fu_type = contr1_i[CONTR_MEMRE_INDEX] | contr1_i[CONTR_MEMWR_INDEX];
					// Mark destination as not ready
					if (src_ready[rs[i].dest] == 1'b1 && rs[i].dest != 0) begin
						src_ready[rs[i].dest] = 1'b0;
					end
					else begin
						$display("Error: new RS entry destination already marked as not ready");
					end
					break;
				end
			end
		end
		
		// Mark scheduled FUs as done
		if (alu_issue[0].used == 1'b1 && alu_issue[0].done == 1'b0) begin
			alu_issue[0].done = 1'b1;
		end
		if (alu_issue[1].used == 1'b1 && alu_issue[1].done == 1'b0) begin
			alu_issue[1].done = 1'b1;
		end
		if (mem_issue.used == 1'b1 && mem_issue.done == 1'b0) begin
			mem_issue.done = 1'b1;
		end
		
	end
	
	// Sending complete signal after ALU values are ready
	always @ (negedge clk_i) begin
		if (alu_issue[0].used == 1'b1 && alu_issue[0].done == 1'b1) begin
			en_complete_instr0_o = 1'b1;
			index_complete_instr0_o = alu_issue[0].rob_index;
			val_complete_instr0_o = fu_result[0];
			pc_complete_instr0_o = alu_issue[0].pc;
			complete_dest0 = alu_issue[0].dest;
			complete_contr0 = alu_issue[0].contr;
		end
		// If not done, don't send complete
		else begin
			en_complete_instr0_o = 1'b0;
		end
		if (alu_issue[1].used == 1'b1 && alu_issue[1].done == 1'b1) begin
			en_complete_instr1_o = 1'b1;
			index_complete_instr1_o = alu_issue[1].rob_index;
			val_complete_instr1_o = fu_result[1];
			pc_complete_instr1_o = alu_issue[1].pc;
			complete_dest1 = alu_issue[1].dest;
			complete_contr1 = alu_issue[1].contr;
		end
		// If not done, don't send complete
		else begin
			en_complete_instr1_o = 1'b0;
		end
		if (mem_issue.used == 1'b1 && mem_issue.done == 1'b1) begin
			en_complete_instr2_o = 1'b1;
			index_complete_instr2_o = mem_issue.rob_index;
			val_complete_instr2_o = fu_result[2];
			pc_complete_instr2_o = mem_issue.pc;
			complete_dest2 = mem_issue.dest;
			complete_contr2 = mem_issue.contr;
		end
		// If not done, don't send complete
		else begin
			en_complete_instr2_o = 1'b0;
		end
	end

endmodule