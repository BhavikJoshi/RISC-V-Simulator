module rename_tb(old_dest0, old_dest1, new_dest0, new_dest1, p_rs10, p_rs11, p_rs20, p_rs21);

	localparam NUM_A_REGS = 32; 
	localparam NUM_P_REGS = 64;
	
	reg clk, en_free_reg0, en_free_reg1, en_new_dest0, en_new_dest1;
	reg [$clog2(NUM_P_REGS)-1:0] free_reg0, free_reg1;
	reg [$clog2(NUM_A_REGS)-1:0] rd0, rd1, rs10, rs11, rs20, rs21;
	
	output wire [$clog2(NUM_P_REGS)-1:0] old_dest0, old_dest1, new_dest0, new_dest1, p_rs10, p_rs11, p_rs20, p_rs21;
	wire rename_stage_pregs_full;
	
	initial begin
		clk = 0;
		en_free_reg0 = 0;
		en_free_reg1 = 0;
		en_new_dest0 = 1;
		en_new_dest1 = 1;
		free_reg0 = 0;
		free_reg1 = 0;
		rd0 = 1;
		rd1 = 2;
		rs10 = 0;
		rs11 = 0;
		rs20 = 0;
		rs21 = 0;
		#5 clk = 1;
		#5 clk = 0;
		rd0 = 3;
		rd1 = 3;
		rs10 = 1;
		rs11 = 2;
		rs20 = 3;
		rs21 = 1;
		#5 clk = 1;
		#5 clk = 0;
		en_free_reg0 = 1;
		en_free_reg1 = 1;
		free_reg0 = 1;
		free_reg1 = 2;
		rd0 = 1;
		rd1 = 5;
		rs10 = 3;
		rs11 = 2;
		rs20 = 3;
		rs21 = 1;
		#5 clk = 1;
		#5 clk = 0;
		free_reg0 = 3;
		free_reg1 = 1;
		rd0 = 10;
		rd1 = 12;
		rs10 = 3;
		rs11 = 1;
		rs20 = 5;
		rs21 = 1;
		#5 clk = 1;
		#15 $stop();
	end

	register_renamer #(NUM_A_REGS, NUM_P_REGS) R0 (.clk_i(clk), .en_free_reg0_i(en_free_reg0), .en_free_reg1_i(en_free_reg1), .free_reg0_i(free_reg0), .free_reg1_i(free_reg1), .en_new_dest0_i(en_new_dest0),
							.en_new_dest1_i(en_new_dest0), .assign_dest0_i(rd0), .assign_dest1_i(rd1), .get_src10_i(rs10), .get_src11_i(rs11), .get_src20_i(rs20),
							.get_src21_i(rs21), .old_dest0_o(old_dest0), .old_dest1_o(old_dest1), .p_dest0_o(new_dest0), .p_dest1_o(new_dest1), .p_src10_o(p_rs10), .p_src11_o(p_rs11), .p_src20_o(p_rs20), .p_src21_o(p_rs21), .no_pregs_left_o(rename_stage_pregs_full));

endmodule