module _16BIT_4to1MUX ( input logic [15:0] dIn0, dIn1, dIn2, dIn3,
					 input logic [1:0] select,
					 output logic [15:0] dOut);
					 
	always_comb begin
		unique case ( select )
			2'b00: dOut = dIn0;
			2'b01: dOut = dIn1;
			2'b10: dOut = dIn2;
			2'b11: dOut = dIn3;
		endcase
	end
					 
					 
endmodule