module dispatch_issue #(parameter WORD_SIZE = 32, NUM_A_REGS = 32, NUM_P_REGS = 64, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000,
								ALU_XOR = 4'b1000, ALU_SRA = 4'b1001, CONTR_SIG_SIZE = 5, CONTR_VALID_INDEX = 0, CONTR_REGWRITE_INDEX = 1, CONTR_ALUSRC_INDEX = 2,
								CONTR_MEMRE_INDEX = 3, CONTR_MEMWR_INDEX = 4, ROB_SIZE = 64)
	(
		input clk_i,
		input new_row0_i;
		input new_row1_i;

	);

	localparam NUM_RS_ROWS = 64;
	localparam NUM_ALU_FUS = 2;
	localparam NUM_MEM_FUS = 1;
	localparam FU_ALU = 0;
	localparam FU_MEM = 1;
	
	typedef struct packed {
		reg use;
		reg [$clog2(NUMP_P_REGS)-1:0] dest;
		reg [$clog2(NUMP_P_REGS)-1:0] rs1;
		reg [WORD_SIZE-1:0] rs1_val;
		reg [$clog2(NUMP_P_REGS)-1:0] rs2;
		reg [WORD_SIZE-1:0] rs2_val;
		reg [WORD_SIZE-1:0] imm;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg fu_type;
		reg [$clog2(ROB_SIZE)-1:0] rob_index;
	} rs_entry;
	
	typedef struct packed {
		reg use;
		reg [$clog2(NUMP_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] data0;
		reg [WORD_SIZE-1:0] data1;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(ROB_SIZE)-1:0] rob_index;
		wire [WORD_SIZE-1:0] result;
	} fu_issue;
	
	typedef rs_entry rs [0:NUM_RS_ROWS-1];
	
	typedef fu_issue alu0_issue;
	typedef fu_issue alu1_issue;
	typedef fu_issue mem_issue;
	
	reg src_ready [0:NUM_P_REGS];
	reg fu_ready [0:NUM_ALU_FS + NUM_MEM_FUS-1];
	
	initial begin
		integer i;
		for (i = 0 ; i < NUM_RS_ROWS; i++) begin
			rs[i].use = 0;
		end
		for (i = 0 ; i < NUM_P_REGS; i++) begin
			src_ready[i] = 1'b1;
		end
		for (i = 0 ; i < NUM_ALU_FS + NUM_MEM_FUS; i++) begin
			fu_ready[i] = 1'b1;
		end
	end
	
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU0 (.alu_op_i(alu0_issue.alu_op), alU_data0_i(alu0_issue.data0), alu_data1_i(alu0_issue.data1), result_o(alu0_issue.result), zero_o());
				 
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU1 (.alu_op_i(alu1_issue.alu_op), alU_data0_i(alu1_issue.data0), alu_data1_i(alu1_issue.data1), result_o(alu0_issue.result), zero_o());
	
	always @ (posedge clk) begin
		integer i;
		if (alu0_issue.use == 1'b1) begin
			// TODO: Give complete signal to ROB for this dest
			// Forward RS1 and RS2 values to RS from ALU0
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				// If RS entry is valid
				if (rs[i].use == 1'b1) begin
					// Forward RS1
					if (rs[i].rs1 == alu0_issue.dest) begin
						rs[i].rs1_val = alu0_issue.result;
					end
					// Forward RS2
					if (rs[i].rs2 == alu0_issue.dest) begin
						rs[i].rs2_val = alu0_issue.result;
					end
				end
			end
			// Mark FUs and SRCs as ready
			alu0_issue.use = 1'b0;
			src_ready[alu0_issue.dest] = 1'b1;
			fu_ready[0] = 1'b1;
		end
		if (alu1_issue.use == 1'b1) begin
			// TODO: Give complete signal to ROB for this dest
			// Forward RS1 and RS2 values to RS from ALU0
			for (i = 0; i < NUM_RS_ROWS; i++) begin
				// If RS entry is valid
				if (rs[i].use == 1'b1) begin
					// Forward RS1
					if (rs[i].rs1 == alu1_issue.dest) begin
						rs[i].rs1_val = alu1_issue.result;
					end
					// Forward RS2
					if (rs[i].rs2 == alu1_issue.dest) begin
						rs[i].rs2_val = alu1_issue.result;
					end
				end
			end
			alu1_issue.use = 1'b0;
			src_ready[alu1_issue.dest] = 1'b1;
			fu_ready[1] = 1'b1;
		end
		// TODO: MEM FU readiness
		// Add incoming instructions to RS
		// As soon as add, mark dest regs as unready
		if (new_row0_i) begin
		end
		if (new_row1_i) begin
		end
		// Schedule instructions from RS to FUs
		for (i = 0; i < NUM_RS_ROW; i++) begin
			// If valid entry
			if (rs[i].use == 1'b1) begin
				// If RS1 ready and (SRC is IMM or RS2 is ready)
				if (src_ready[rs[i].rs1] == 1'b1 && (rs[i].contr[CONTR_ALUSRC_INDEX] == 1'b1 || src_ready[rs[i].rs2] == 1'b1)) begin 
					// If is an ALU instructions
					if (rs[i].fu_type == FU_ALU) begin
						// If ALU0 is ready
						if (fu_ready[0] == 1'b1) begin
							alu0_issue.use = 1'b1;
							alu0_issue.dest = rs[i].dest;
							alu0_issue.data0 = rs[i].rs1_val;
							alu0_issue.data1 = rs[i].contr[CONTR_ALUSRC_INDEX] == 1'b1 ? rs[i].imm : rs[i].rs2_val;
							alu0_issue.contr = rs[i].contr;
							alu0_issue.alu_op = rs[i].alu_op;
							alu0_issue.rob_index = rs[i].rob_index;
						end
					end
				end
			end
		end
		
	end
		// TODO:
		// add 2 instructions to reservation station
		// schedule 2 ready instructions into ALU and remove them from reservation station
		// mark dest regs as unready
		// mark FUs are not ready
		

endmodule