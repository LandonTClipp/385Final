//synchronizer with reset to 1 (d_ff)
module sync (
	input  logic Clk, Reset, d, 
	output logic q
);

//initial
//begin	
//	q <= 1'b0;
//end

always_ff @ (posedge Clk or posedge Reset)
begin
	if (Reset)
		q <= 1'b1;
	else
		q <= d;
end

endmodule