module register_file #(parameter NUM_P_REGS = 64, WORD_SIZE = 32)
	(
		input clk_i,
		input reg_write0_i,
		input reg_write1_i,
		input [$clog2(NUM_P_REGS)-1:0] dest0_i,
		input [$clog2(NUM_P_REGS)-1:0] dest1_i,
		input [WORD_SIZE-1:0] word0,
		input [WORD_SIZE-1:0] word1,
		input [$clog2(NUM_P_REGS)-1:0] read_reg0_i,
		input [$clog2(NUM_P_REGS)-1:0] read_reg1_i,
		input [$clog2(NUM_P_REGS)-1:0] read_reg2_i,
		input [$clog2(NUM_P_REGS)-1:0] read_reg3_i,
		output [WORD_SIZE-1:0] val_reg0_o,
		output [WORD_SIZE-1:0] val_reg1_o,
		output [WORD_SIZE-1:0] val_reg2_o,
		output [WORD_SIZE-1:0] val_reg3_o
	);
	
	reg [WORD_SIZE-1:0] rf [0:NUM_P_REGS-1];
	
	// Initialize Register File to 0s
	initial begin
		integer i;
		for (i = 0; i < NUM_P_REGS; i++) begin
			rf[i] = 0;
		end
	end
	
	// Register File Read Ports
	assign val_reg0_o = rf[read_reg0_i];
	assign val_reg1_o = rf[read_reg1_i];
	assign val_reg2_o = rf[read_reg2_i];
	assign val_reg3_o = rf[read_reg3_i];
	
	
	// Write to Register File (blocking) To Ensure Order Correctness
	always @ (posedge clk_i) begin
		if (reg_write0_i && dest0_i != 0) begin
			rf[dest0_i] = word0;
		end
		if (reg_write1_i && dest0_i != 0) begin
			rf[dest1_i] = word1;
		end
	end
	
	
endmodule
