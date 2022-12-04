module reorder_buffer #(parameter PC_SIZE = 32, WORD_SIZE = 32, NUM_P_REGS = 64, CONTR_SIG_SIZE = 5, ROB_SIZE = 16)
	(
		input clk_i,
		input en_reserve_instr0_i,
		input en_reserve_instr1_i,
		input [$clog2(NUM_P_REGS)-1:0] instr0_dest_i,
		input [$clog2(NUM_P_REGS)-1:0] instr1_dest_i,
		input [WORD_SIZE-1:0] instr0_val_i,
		input [WORD_SIZE-1:0] instr1_val_i,
		input [$clog2(NUM_P_REGS)-1:0] instr0_old_dest_i,
		input [$clog2(NUM_P_REGS)-1:0] instr1_old_dest_i,
		input [CONTR_SIG_SIZE-1] instr0_contr_i,
		input [CONTR_SIG_SIZE-1] instr1_contr_i,
		input [PC_SIZE-1:0] instr0_pc_i,
		input [PC_SIZE-1:0] instr1_pc_i,
		input en_complete_instr0_i,
		input en_complete_instr1_i,
		input en_complete_instr2_i,
		input [$clog2(ROB_SIZE)-1:0] complete_indx0_i,
		input [$clog2(ROB_SIZE)-1:0] complete_indx1_i,
		input [$clog2(ROB_SIZE)-1:0] complete_indx2_i,
		input [$clog2(ROB_SIZE)-1:0] complete_pc0_i,
		input [$clog2(ROB_SIZE)-1:0] complete_pc1_i,
		input [$clog2(ROB_SIZE)-1:0] complete_pc2_i,
		input [WORD_SIZE-1:0] complete_val0_i,
		input [WORD_SIZE-1:0] complete_val1_i,
		input [WORD_SIZE-1:0] complete_val2_i,
		output reg rob_fwd_table_entry_s rob_fwd_table_o [0:NUM_P_REGS-1];
		output reg en_retire_dest0_o,
		output reg en_retire_dest1_o,
		output reg [$clog2(NUM_P_REGS)-1:0] retire_dest0_o,
		output reg [$clog2(NUM_P_REGS)-1:0] retire_dest1_o,
		output reg [WORD_SIZE-1:0] retire_val0_o, 
		output reg [WORD_SIZE-1:0] retire_val1_o,
		output tail_indx_0,
		output tail_indx_1, 
		output rob_full_o,
	);
	
	typedef rob_entry rob [0:ROB_SIZE-1]:
	
	wire empty = (counter == 0);
	wire full = (counter == ROB_SIZE);
	int counter;
	reg [$clog2(ROB_SIZE)-1:0] head;
	reg [$clog2(ROB_SIZE)-1:0] tail;
	
	typedef struct packed {
		reg valid;
		reg [$clog2(NUM_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] val;
		reg [$clog2(NUM_P_REGS)-1:0] old_dest;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [PC_SIZE-1:0] pc;
		reg complete;
	} rob_entry;
	
	
	assign tail_indx_0 = tail;
	assign tail_indx_1 = (tail + 1) % ROB_SIZE;
	
	// Output ROB full if can't put 2 instructions in in this cycle
	assign rob_full_o = counter >= ROB_SIZE - 1;

	
	initial begin
		counter = 0;
		head = 0;
		tail = 0;
		integer i;
		for (i = 0; i < ROB_SIZE; i++) begin
			rob[i].valid = 1'b0;
		end
		for (i = 0; i < NUM_P_REGS; i++) begin
			rob_fwd_table_o[i].to_fwd = 1'b0;
		end
	end
	
	always @ (posedge clk_i) begin
		integer i;
		// Add entries to ROB
		if (en_reserve_instr0_i) begin
			if (!full) begin
				// Fill Entry
				rob[tail].valid = 1'b1;
				rob[tail].dest = instr0_dest_i;
				rob[tail].old_dest = instr0_old_dest_i;
				rob[tail].contr = instr0_contr_i;
				rob[tail].pc = instr0_pc_i;
				rob[tail].complete = 1'b0;
				// Inc Queue
				tail = (tail + 1) % ROB_SIZE;
				counter = counter + 1;
			end
		end
		if (en_reserve_instr1_i) begin
			if (!full) begin
				// Fill Entry
				rob[tail].valid = 1'b1;
				rob[tail].dest = instr1_dest_i;
				rob[tail].old_dest = instr1_old_dest_i;
				rob[tail].contr = instr1_contr_i;
				rob[tail].pc = instr1_pc_i;
				rob[tail].complete = 1'b0;
				// Inc Queue
				tail = (tail + 1) % ROB_SIZE;
				counter = counter + 1;
			end
		end
		
		// Retire entries from ROB
		en_retire_dest0_o = 1'b0;
		en_retire_dest1_o = 1'b0;
		if (!empty) begin
			if (rob[head].valid == 1'b1 && rob[head].complete == 1'b1) begin
				en_retire_dest0_o = rob[head].contr[CONTR_REGWRITE_INDEX];
				retire_dest0_o = rob[head].dest;
				retire_val0_o = rob[head].val;
				rob_fwd_table_o[rob[head].dest].to_fwd = 1'b0;
				rob[head].valid = 1'b0;
				head = (head + 1) % ROB_SIZE;
				counter = counter - 1;
			end
		end
		if (!empty) begin
			if (rob[head].valid == 1'b1 && rob[head].complete == 1'b1) begin
				en_retire_dest1_o = rob[head].contr[CONTR_REGWRITE_INDEX];
				retire_dest1_o = rob[head].dest;
				retire_val1_o = rob[head].val;
				rob_fwd_table_o[rob[head].dest].to_fwd = 1'b0;
				rob[head].valid = 1'b0;
				head = (head + 1) % ROB_SIZE;
				counter = counter - 1;
			end
		end
		
		// Complete Entries in ROB
		if (en_complete_instr0_i) begin
			if (rob[complete_indx0_i].valid == 1'b0) begin
				$display("Error completing unused entry in ROB");
			end
			else if (rob[complete_indx0_i].pc != complete_pc0_i) begin
				$display("Error completing non-matching entry in ROB");
			end
			// Can succesfully complete instruction
			else begin
				rob[complete_indx0_i].val = complete_val0_i;
				rob[complete_indx0_i].complete = 1'b1;
				rob_fwd_table_o[rob[complete_indx0_i].dest].to_fwd = rob[complete_indx0_i].contr[CONTR_REGWRITE_INDEX];
				rob_fwd_table_o[rob[complete_indx0_i].dest].val = complete_val0_i;
			end
		end
		if (en_complete_instr1_i) begin
			if (rob[complete_indx1_i].valid == 1'b0) begin
				$display("Error completing unused entry in ROB");
			end
			else if (rob[complete_indx1_i].pc != complete_pc1_i) begin
				$display("Error completing non-matching entry in ROB");
			end
			// Can succesfully complete instruction
			else begin
				rob[complete_indx1_i].val = complete_val1_i;
				rob[complete_indx1_i].complete = 1'b1;
				rob_fwd_table_o[rob[complete_indx1_i].dest].to_fwd = rob[complete_indx1_i].contr[CONTR_REGWRITE_INDEX];
				rob_fwd_table_o[rob[complete_indx1_i].dest].val = complete_val1_i;
			end
		end
		if (en_complete_instr2_i) begin
			if (rob[complete_indx2_i].valid == 1'b0) begin
				$display("Error completing unused entry in ROB");
			end
			else if (rob[complete_indx2_i].pc != complete_pc2_i) begin
				$display("Error completing non-matching entry in ROB");
			end
			// Can succesfully complete instruction
			else begin
				rob[complete_indx2_i].val = complete_val2_i;
				rob[complete_indx2_i].complete = 1'b1;
				rob_fwd_table_o[rob[complete_indx2_i].dest].to_fwd = rob[complete_indx2_i].contr[CONTR_REGWRITE_INDEX];
				rob_fwd_table_o[rob[complete_indx2_i].dest].val = complete_val2_i;
			end
		end
	end
	
endmodule