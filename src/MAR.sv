module MAR(input logic [15:0] toPC, 
                      input logic LD_PC,
							 input logic Clk,
							 input logic Reset,
							 output logic [15:0] PC
							 
							 );


always_ff @ (posedge Clk or posedge Reset) begin
   if (Reset) 
	   PC<= 16'b0;
	else
	begin
	if (LD_PC == 1'b1)
		PC <= toPC;
	else 
	   PC <= PC;
	end
end
endmodule