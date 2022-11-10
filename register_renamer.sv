module register_renamer #(parameter NUM_A_REGS = 32, NUM_P_REGS = 64)
	(
		input clk_i,
		input en_free_reg0_i,
		input en_free_reg1_i,
		input [$clog2(NUM_P_REGS)-1:0] free_reg0_i,
		input [$clog2(NUM_P_REGS)-1:0] free_reg1_i,
		input en_new_dest0_i,
		input en_new_dest1_i,
		input [$clog2(NUM_A_REGS)-1:0] assign_dest0_i,
		input [$clog2(NUM_A_REGS)-1:0] assign_dest1_i,
		input [$clog2(NUM_A_REGS)-1:0] get_src10_i,
		input [$clog2(NUM_A_REGS)-1:0] get_src11_i,
		input [$clog2(NUM_A_REGS)-1:0] get_src20_i,
		input [$clog2(NUM_A_REGS)-1:0] get_src21_i,
		output reg [$clog2(NUM_P_REGS)-1:0] old_dest0_o,
		output reg [$clog2(NUM_P_REGS)-1:0] old_dest1_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_dest0_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_dest1_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_src10_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_src11_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_src20_o,
		output reg [$clog2(NUM_P_REGS)-1:0] p_src21_o,
		output reg no_pregs_left_o
	);
	
	// Free pool
	reg free_pool [0:NUM_P_REGS-1];
	integer num_free_regs;
	
	// Register Alias Table
	reg [$clog2(NUM_P_REGS)-1:0] rat [0:NUM_A_REGS-1];
	
	// Initialize free pool and RAT
	// TODO: initial a -> p mapping
	initial begin
		integer i;
		// Initially, all registers are mapped to 0
		for (i = 0; i < NUM_A_REGS; i++) begin
			rat[i] = 0;
		end
		// All P-regs are free
		for (i = 0; i < NUM_P_REGS; i++) begin
			free_pool[i] = 1'b1;
		end
	end
	
	// Need to know if less than two free P-registers left
	always @ (*) begin
		integer i;
		num_free_regs = 0;
		for (i = 0; i < NUM_P_REGS; i++) begin
			num_free_regs += free_pool[i];
		end
	end
	// Send signal to stall if no more free P-regs
	assign no_pregs_left_o = num_free_regs < 2;

	always @ (posedge clk_i) begin
		// Update Free Pool
		integer i;
		// Free retired registers from ROB
		if (en_free_reg0_i == 1'b1 && free_reg0_i != 0) begin
			if (free_pool[free_reg0_i] == 1'b0) begin
				free_pool[free_reg0_i] = 1'b1;
			end
			else begin
				$display("Error freeing already free P-reg %0d\n", free_reg0_i);
			end
		end
		if (en_free_reg1_i == 1'b1 && free_reg1_i != 0) begin
			if (free_pool[free_reg1_i] == 1'b0) begin
				free_pool[free_reg1_i] = 1'b1;
			end
			else begin
				$display("Error freeing already free P-reg %0d\n", free_reg1_i);
			end
		end
		// Allocate free destination registers
		if (en_new_dest0_i == 1'b1) begin
			if (assign_dest0_i == 0) begin
				p_dest0_o = 0;
			end
			else begin
				for (i = 1; i < NUM_P_REGS; i++) begin
					if (free_pool[i] == 1'b1) begin
						free_pool[i] = 1'b0;
						p_dest0_o = i[$clog2(NUM_P_REGS)-1:0];
						break;
					end
				end
			end
		end
		if (en_new_dest1_i == 1'b1) begin
			if (assign_dest1_i == 0) begin
				p_dest1_o = 0;
			end
			else begin
				for (i = 1; i < NUM_P_REGS; i++) begin
					if (free_pool[i] == 1'b1) begin
						free_pool[i] = 1'b0;
						p_dest1_o = i[$clog2(NUM_P_REGS)-1:0];
						break;
					end
				end
			end
		end
		
		// Update RAT
		// Get source register translations
		p_src10_o = rat[get_src10_i];
		p_src11_o = rat[get_src11_i];
		p_src20_o = rat[get_src20_i];
		p_src21_o = rat[get_src21_i];
		
		// If dest0 was re-translated
		if (en_new_dest0_i == 1'b1) begin
			// Get old dest reg
			old_dest0_o = rat[assign_dest0_i];
			// Set new dest reg
			if (p_dest0_o != 0) begin
				rat[assign_dest0_i] = p_dest0_o;
			end
		end
		// If dest1 was retranslated
		if (en_new_dest1_i == 1'b1) begin
			// Get old dest reg
			old_dest1_o = rat[assign_dest1_i];
			// Set new dest reg
			if (p_dest1_o != 0) begin
				rat[assign_dest1_i] = p_dest1_o;
			end
		end
		
	end


endmodule
