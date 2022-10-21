module decode_stage #(parameter INSTR_SIZE = 32)(instr, clk, val);

	input reg [INSTR_SIZE-1:0] instr;
	input clk;
	
	output reg [INSTR_SIZE-1:0] val;
	
	always @ (posedge clk) begin
		val <= instr;
	end
	
endmodule
