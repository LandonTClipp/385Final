module BusMUX (input logic GatePC, GateMDR, GateALU, GateMARMUX,
							input logic [15:0] fromMARMUX, fromPC, fromALU, fromMDR,
							output logic [15:0] busOut);
							
/* Our internal MUX will be represented by one-hot encoding */
logic [3:0] internalMUXAddr;

assign internalMUXAddr[0] = GatePC;
assign internalMUXAddr[1] = GateMDR;
assign internalMUXAddr[2] = GateALU;
assign internalMUXAddr[3] = GateMARMUX;

always_comb begin
	
	case (internalMUXAddr)
	4'b0001: busOut = fromPC; 
	4'b0010: busOut = fromMDR;
	4'b0100: busOut = fromALU;
	4'b1000: busOut = fromMARMUX;
	4'b0000: busOut[15:0] = 16'b0000000000000000;		// If no gates are set high, busOut will simply be 0's
	/* One of the above conditions should always be met, default should never execute.
	   If it does, the bus will contain all 1's which can aid in debugging.
	*/
	default: busOut[15:0] = 16'b1111111111111111;

	endcase
end						
endmodule							