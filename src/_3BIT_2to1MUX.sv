module _3BIT_2to1MUX ( input logic [2:0] dIn0, dIn1,
					 input logic select,
					 output logic [2:0] dOut);
	always_comb begin
		unique case ( select )
			1'b0: dOut = dIn0;
			1'b1: dOut = dIn1;
		endcase
	end
					 
					 
endmodule