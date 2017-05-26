module reg16 (input  logic Clk, Reset, LD_REG,
                      input  logic [15:0] dIn,
                      output logic [15:0] dOut);

	wire w1;
	wire w2;
	// Registers will not be shifting in data. Only parallel load.
	reg_8  reg_A (.Clk(Clk), .Reset(Reset), .Shift_In(1'b0), .Load(LD_REG),
	               .Shift_En(1'b0), .D(dIn[15:8]), .Shift_Out(w1), .Data_Out(dOut[15:8]));
	
	reg_8  reg_B (.Clk(Clk), .Reset(Reset), .Shift_In(w1), .Load(LD_REG),
	               .Shift_En(1'b0), .D(dIn[7:0]), .Shift_Out(w2), .Data_Out(dOut[7:0]));
						
		

endmodule
