module IOhandler( input logic clk,
						input logic reset,
						input logic run,
						input logic [4:0] writeRequest,
						input logic [4:0] readRequest, 
						input logic [15:0] ADDR0,
						input logic [15:0] DATA0,
						input logic [15:0] ADDR1,
						input logic [15:0] DATA1,
						input logic [15:0] ADDR2,
						input logic [15:0] DATA2,
						input logic [15:0] ADDR3,
						input logic [15:0] DATA3,
						input logic [15:0] ADDR4,
						input logic [15:0] DATA4,
						input logic [15:0] fromTristate,
						
						output logic [15:0] toTristate,
						output logic [15:0] addressToSRAM,
						output logic [15:0] DataToCPUs,
						// WE and RE are active LOW
						output logic SRAM_WE,
						output logic SRAM_RE,
						output logic SRAM_CE,
						output logic [4:0] requestDone);
						
/* A queueing operation must be performed to keep track of requests */
logic [2:0] first, first_next;	// binary number denoting which node is first, second, third etc.
logic [2:0] second, second_next;	// 111 will denote "empty"
logic [2:0] third, third_next;
logic [2:0] fourth, fourth_next;
logic [2:0] fifth, fifth_next;
logic [4:0] requestPrev;			// Keeps track of which node was requesting an operation (read or write) in previous cycle
logic [4:0] readRequestPrev;
logic [4:0] writeRequestPrev;
logic reset_ah;

assign reset_ah = ~reset;

/*
	NOTE:
		Asynchronous SRAM is guaranteed to be ready within 1 clock cycle if the clock is 50MHz or below
*/

/*

		first			--< second        --< third
		  ^		  /		^         /       ^
		  ^		 /			^		   /        ^				...
		first_next		second_next			  third_next
			^					^						^
			^					^						^
			-----------------------------------
			|		    Queue emplacer			 |
			|_________________________________|

*/

logic [1:0] pause;

always_ff @ (posedge clk or posedge reset_ah) begin
	pause = pause + 1;
	if ( reset_ah ) begin
	 first = 3'b111;
	 second = 3'b111;
	 third = 3'b111;
	 fourth = 3'b111;
	 fifth = 3'b111;
	 first_next = 3'b111;
	 second_next = 3'b111;
	 third_next = 3'b111;
	 fourth_next = 3'b111;
	 fifth_next = 3'b111;
	 requestPrev = 5'b00000;
	 readRequestPrev = 5'b0;
	 writeRequestPrev = 5'b0;
	 pause = 2'b00;
	end
	else if ( 1 ) begin
	
	unique case ( first )
		3'd0: requestDone[4:0] = 5'b00001;
		3'd1: requestDone[4:0] = 5'b10000;
		3'd2: requestDone[4:0] = 5'b01000;
		3'd3: requestDone[4:0] = 5'b00100;
		3'd4: requestDone[4:0] = 5'b00010;
		default:
				requestDone[4:0] = 5'b00000;
	endcase
		/* NOTE
			Do NOT use non-blocking assignments ( <= ) in this block!!!
			Blocking assignments are desired here.
		*/
	
		first = first_next;
		second = second_next;
		third = third_next;
		fourth = fourth_next;
		fifth = fifth_next;
		
		
		
		
		/* Believe me, assigning the next variables to each other is the correct
				way to do this...
		*/
		first_next[2:0] = second_next[2:0];
		second_next[2:0] = third_next[2:0];
		third_next[2:0] = fourth_next[2:0];
		fourth_next[2:0] = fifth_next[2:0];
		fifth_next = 3'b111;
		
		/******************
		 * QUEUE EMPLACER *
		 ******************/
		 
		 
		 if ( ((readRequestPrev[4] != readRequest[4]) && (readRequest[4] != 1'b0 )) ||
				((writeRequestPrev[4] != writeRequest[4]) && (writeRequest[4] != 1'b0 )) ) begin
		//if ( (requestPrev[4] != writeRequest[4] ^ readRequest[4]) && (writeRequest[4] ^ readRequest[4] == 1'b1) ) begin			// if slave 1 making a new request
			if ( first_next == 3'd7 ) 
				first_next = 3'd1;
			else if ( second_next == 3'd7 )
				second_next = 3'd1;
			else if ( third_next == 3'd7 )
				third_next = 3'd1;
			else if ( fourth_next == 3'd7 )
				fourth_next = 3'd1;
			else
				fifth_next = 3'd1;
		end
		
		if ( ((readRequestPrev[3] != readRequest[3]) && (readRequest[3] != 1'b0 )) ||
				((writeRequestPrev[3] != writeRequest[3]) && (writeRequest[3] != 1'b0 )) ) begin
		//if ( (requestPrev[3] != writeRequest[3] ^ readRequest[3]) && (writeRequest[3] ^ readRequest[3] == 1'b1) ) begin			// if slave 2 making a new request
			if ( first_next == 3'd7 ) 
				first_next = 3'd2;
			else if ( second_next == 3'd7 )
				second_next = 3'd2;
			else if ( third_next == 3'd7 )
				third_next = 3'd2;
			else if ( fourth_next == 3'd7 )
				fourth_next = 3'd2;
			else
				fifth_next = 3'd2;
		end
		
		if ( ((readRequestPrev[2] != readRequest[2]) && (readRequest[2] != 1'b0 )) ||
				((writeRequestPrev[2] != writeRequest[2]) && (writeRequest[2] != 1'b0 )) ) begin
		//if ( (requestPrev[2] != writeRequest[2] ^ readRequest[2]) && (writeRequest[2] ^ readRequest[2] == 1'b1) ) begin			// slave 3
			if ( first_next == 3'd7 ) 
				first_next = 3'd3;
			else if ( second_next == 3'd7 )
				second_next = 3'd3;
			else if ( third_next == 3'd7 )
				third_next = 3'd3;
			else if ( fourth_next == 3'd7 )
				fourth_next = 3'd3;
			else
				fifth_next = 3'd3;
		end
		
		if ( ((readRequestPrev[1] != readRequest[1]) && (readRequest[1] != 1'b0 )) ||
				((writeRequestPrev[1] != writeRequest[1]) && (writeRequest[1] != 1'b0 )) ) begin
		//if ( (requestPrev[1] != writeRequest[1] ^ readRequest[1]) && (writeRequest[1] ^ readRequest[1] == 1'b1) ) begin			// slave 4
			if ( first_next == 3'd7 ) 
				first_next = 3'd4;
			else if ( second_next == 3'd7 )
				second_next = 3'd4;
			else if ( third_next == 3'd7 )
				third_next = 3'd4;
			else if ( fourth_next == 3'd7 )
				fourth_next = 3'd4;
			else
				fifth_next = 3'd4;
		end
		
		if ( ((readRequestPrev[0] != readRequest[0]) && (readRequest[0] != 1'b0 )) ||
				((writeRequestPrev[0] != writeRequest[0]) && (writeRequest[0] != 1'b0 )) ) begin
		//if ( (requestPrev[0] != writeRequest[0] ^ readRequest[0]) && (writeRequest[0] ^ readRequest[0] == 1'b1) ) begin			// master
			if ( first_next == 3'd7 ) 
				first_next = 3'd0;
			else if ( second_next == 3'd7 )
				second_next = 3'd0;
			else if ( third_next == 3'd7 )
				third_next = 3'd0;
			else if ( fourth_next == 3'd7 )
				fourth_next = 3'd0;
			else
				fifth_next = 3'd0;
		end
		
		
		
		
		
		/* Keep track of the previous request state to determine, later on, if any new requests
		have arrived
	*/
	requestPrev[4:0] = writeRequest[4:0] ^ readRequest[4:0];
	readRequestPrev = readRequest;
	writeRequestPrev = writeRequest;
	
	end // end if(reset) else if (~pause)

	
	
	
	
end
 



	/*******************
	 * SRAM CONTROLLER *
	 *******************/
/*
	This block will control, via MUXes, which address is going to RAM and also
	which data lines are assigned to data coming from SRAM.
*/

/*module tristate #(N = 16) (
	input logic Clk, 
	input logic tristate_output_enable,
	input logic [N-1:0] Data_write, // Data from Mem2IO
	output logic [N-1:0] Data_read, // Data to Mem2IO
	inout wire [N-1:0] Data // inout bus to SRAM
);
*/




// Populate the bus going to CPUs with fromTristate
assign DataToCPUs = fromTristate;

/* Was running into problems with SRAM being overwritten as soon as
  circuit was uploaded to board. This was coming from the SRAM_CE, SRAM_WE, 
  and SRAM_RE signals being 0 for a very small amount of time before the first 
  positive clock pulse. So I'm assigning the CE to be 1 (inactive) until the first clock
  pulse (where the control signals will then be properly initialized).
 */
logic init = 1'b1;
assign SRAM_CE = init;
logic start;
logic [15:0] addressToSRAM_buf;
logic SRAM_WE_buf;

assign addressToSRAM = addressToSRAM_buf;



always_ff @(posedge clk or posedge reset_ah) begin

	if ( reset_ah ) begin
		SRAM_WE = 1'b1;
		SRAM_RE = 1'b1;
	end
	else begin
	if ( run || ~init) begin
	 init = 1'b0;
	end
	// Active LOW
	
	
	if ( 1 ) begin
	SRAM_RE = 1'b1;
	SRAM_WE = 1'b1;
	addressToSRAM_buf = 16'hffff;
	start = 1'b1;
	unique case (first)
		default: begin 
		
		end
		3'd0: begin
			addressToSRAM_buf = ADDR0;
			
			if (writeRequest[0] == 1'b1) begin
				SRAM_WE = 1'b0;
				toTristate = DATA0;
			
			end
			else begin
				SRAM_RE = 1'b0;
			
			end
		end
		3'd1: begin
			addressToSRAM_buf = ADDR1;
			
			if (writeRequest[4] == 1'b1) begin
				SRAM_WE = 1'b0;
				toTristate = DATA1;
			end
			else begin
				SRAM_RE = 1'b0;
				
			end
		end
		3'd2: begin
			addressToSRAM_buf = ADDR2;
			
			if (writeRequest[3] == 1'b1) begin
				SRAM_WE = 1'b0;
				toTristate = DATA2;
			end
			else begin
				SRAM_RE = 1'b0;
			end
		end
		3'd3: begin
			addressToSRAM_buf = ADDR3;
			
			if (writeRequest[2] == 1'b1) begin
				SRAM_WE = 1'b0;
				toTristate = DATA3;
			end
			else begin
				SRAM_RE = 1'b0;
			end
		end
		3'd4: begin
			addressToSRAM_buf = ADDR4;
			
			if (writeRequest[1] == 1'b1) begin
				SRAM_WE = 1'b0;
				toTristate = DATA4;
			end
			else begin
				SRAM_RE = 1'b0;
			end
		end
	endcase
	end
	end
end
endmodule