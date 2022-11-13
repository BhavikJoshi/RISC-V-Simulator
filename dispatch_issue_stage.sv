module dispatch_issue #(parameter WORD_SIZE = 32, NUM_A_REGS = 32, NUM_P_REGS = 64, ALU_OP_SIZE = 4, ALU_ADD = 4'b0010, ALU_SUB = 4'b0110, ALU_AND = 4'b0000,
								ALU_XOR = 4'b1000, ALU_SRA = 4'b1001, CONTR_SIG_SIZE = 5, CONTR_VALID_INDEX = 0, CONTR_REGWRITE_INDEX = 1, CONTR_ALUSRC_INDEX = 2,
								CONTR_MEMRE_INDEX = 3, CONTR_MEMWR_INDEX = 4)
	(
		input clk_i,
		input reserve_row0;
		input reserve_row1;
	);

	localparam NUM_RS_ROWS = 1024;
	localparam NUM_ALU_FUS = 2;
	localparam NUM_MEM_FUS = 1;
	localparam FU_ALU = 0;
	localparam FU_MEM = 1;
	
	typedef struct packed {
		reg use;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(NUMP_P_REGS)-1:0] dest;
		reg [$clog2(NUMP_P_REGS)-1:0] rs1;
		reg [WORD_SIZE-1:0] rs1_val;
		reg rs1_ready;
		reg [$clog2(NUMP_P_REGS)-1:0] rs2;
		reg [WORD_SIZE-1:0] rs2_val;
		reg rs2_ready;
		reg [WORD_SIZE-1:0] imm;
		reg fu_type;
		reg rob_num;
	} rs_entry;
	
	typedef struct packed {
		reg use;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [ALU_OP_SIZE-1:0] alu_op;
		reg [$clog2(NUMP_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] data0;
		reg [WORD_SIZE-1:0] data1;
		reg [WORD_SIZE-1:0] result
	} fu_issue;
	
	typedef rs_entry rs [0:NUM_RS_ROWS-1];
	typedef fu_issue fus [0:NUM_ALU_FS + NUM_MEM_FUS-1];
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
	
	//genvar g;
	
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU0 (.alu_op_i(alu0_issue.alu_op), alU_data0_i(alu0_issue.data0), alu_data1_i(alu0_issue.data1), result_o(alu0_issue.result), zero_o());
				 
	alu #(WORD_SIZE, NUM_P_REGS, ALU_OP_SIZE, ALU_ADD, ALU_SUB, ALU_AND,
				 ALU_XOR, ALU_SRA) ALU1 (.alu_op_i(alu1_issue.alu_op), alU_data0_i(alu1_issue.data0), alu_data1_i(alu1_issue.data1), result_o(alu1_issue.result), zero_o());
	
	// always @ (*) begin
		// TODO:
		// look for complete signal from ALU (end of this module last cycle)
		// mark FUs and dest registers as ready
		// forward prev cycle dest registers values back to RS source values
		// add 2 instructions to reservation station
		// schedule 2 ready instructions into ALU and remove them from reservation station
		// mark dest regs as unready
		// mark FUs are not ready
		

endmodule