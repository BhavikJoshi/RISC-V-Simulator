module instruction_reader(val);

	localparam MAX_LINES = 128;
	localparam INSTR_SIZE = 32;
	localparam BYTE_SIZE = 8;
	
	reg [BYTE_SIZE-1:0] instr_mem [0:MAX_LINES-1];
	reg [INSTR_SIZE-1:0] curr_instr;
	reg clk;
	
	output [INSTR_SIZE-1:0] val;

	initial begin
		$readmemh("/Users/piefo/OneDrive/Desktop/189Project/bin.txt", instr_mem);
		clk = 0;
		curr_instr = 0;
		for (int i = 1; i < instr_mem[0] - 3; i = i + 4) begin
			curr_instr = {instr_mem[i+3], instr_mem[i+2], instr_mem[i+1], instr_mem[i]};
			#5 clk = 1;
			#5 clk = 0;
		end
	end

	decode_stage #(32) decoder(.instr(curr_instr), .clk(clk), .val(val));

endmodule

