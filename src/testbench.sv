module testbench();


timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;



			/* BEGIN IOHANDLER TESTBENCH */
			
logic Clk;
logic Reset;
logic Run;



topLevelTestbench topLevel( 
					  .Clk, 
					  .Reset, 
					  .Run
					  );
										

//topLevelTestbench topLevel( 
					//  );
	


// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 
	
initial begin: TEST_VECTORS
Reset = 1;		// active low
Run = 1;


#2 Reset = 0;
#2 Reset = 1;
#10 Run = 0;
#2 Run = 1;



end
			/* END TOPLEVEL TESTBENCH */


endmodule
