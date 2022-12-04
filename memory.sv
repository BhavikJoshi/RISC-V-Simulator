module memory #(parameter WORD_SIZE = 32, MEM_SIZE = 1024)
	(
		input en_mem_i
		input mem_read_i,
		input mem_write_i, 
		input [WORD_SIZE-1:0] addr_base_i,
		input [WORD_SIZE-1:0] addr_offset_i,
		input [WORD_SIZE-1:0] val_i,
		output reg [WORD_SIZE-1:0] val_o,
	);
	
	reg [WORD_SIZE-1:0] memory [0:MEM_SIZE-1];
	
	initial begin
		integer i;
		for (i = 0; i < MEM_SIZE-1; i++) begin
			memory[i] = 0;
		end
		val_o = 0;
	end
	
	
	always @ (posedge en_mem_i) begin
		if (mem_write_i == 1'b1) begin
			memory[addr_base_i + addr_offset_i] = val_i;
		end
		else if (mem_read_i == 1'b1) begin
			val_o = memory[addr_base_i + addr_offset_i];
		end
	end 

endmodule