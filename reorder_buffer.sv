module reorder_buffer #(parameter PC_SIZE = 32, WORD_SIZE = 32, NUM_P_REGS = 64, CONTR_SIG_SIZE = 5, QUEUE_SIZE = 64)
	(
		input clk_i,
		input en_reserve_instr0_i,
		input en_reserve_instr1_i,
		input [$clog2(NUM_P_REGS)-1:0] instr0_dest_i,
		input [WORD_SIZE-1:0] instr0_val_i,
		input [$clog2(NUM_P_REGS)-1:0] instr0_old_dest_i,
		input [CONTR_SIG_SIZE-1] instr0_contr_i,
		input [PC_SIZE-1:0] instr0_pc_i,
		input [$clog2(NUM_P_REGS)-1:0] instr1_dest_i,
		input [WORD_SIZE-1:0] instr1_val_i,
		input [$clog2(NUM_P_REGS)-1:0] instr1_old_dest_i,
		input [CONTR_SIG_SIZE-1] instr1_contr_i,
		input [PC_SIZE-1:0] instr1_pc_i,
		input en_complete_instr0_i,
		input en_complete_instr1_i,
		input [$clog2(QUEUE_SIZE)-1:0] complete_indx0_i,
		input [$clog2(QUEUE_SIZE)-1:0] complete_indx1_i,
		output en_write_dest
		output tail_indx_0,
		output tail_indx_1, 
		output rob_full_o,
	);

	localparam QUEUE_SIZE = 64;
	
	wire empty = (counter == 0);
	wire full = (head == tail) && (empty == 0);
	int counter;
	reg [$clog2(QUEUE_SIZE)-1:0] head;
	reg [$clog2(QUEUE_SIZE)-1:0] tail;
	
	typedef struct packed {
		reg valid;
		reg [$clog2(NUM_P_REGS)-1:0] dest;
		reg [WORD_SIZE-1:0] val;
		reg [$clog2(NUM_P_REGS)-1:0] old_dest;
		reg [CONTR_SIG_SIZE-1:0] contr;
		reg [PC_SIZE-1:0] pc;
		reg complete;
	} rob_entry;
	
	typedef rob_entry rob [0:QUEUE_SIZE-1]:
	
	initial begin
		counter = 0;
		head = 0;
		tail = 0;
		integer i;
		for (i = 0; i < QUEUE_SIZE; i++) begin
			rob[i].valid = 0;
		end
	end
	
	always @ (posedge clk_i) begin
	end
	
endmodule