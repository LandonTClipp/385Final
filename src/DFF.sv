// D flip-flop unit from lecture

module DflipFlop ( input Clk, Reset, Load, D,
              output logic Q);

    always_ff @ (posedge Clk or posedge Reset)
    begin
	 	 if (Reset) 
			  Q <= 1'b0;
		 else if (Load)
				Q <= D;
				else 
				Q <= Q;
    end
endmodule