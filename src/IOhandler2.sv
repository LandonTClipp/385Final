module IOhandler2( input logic clk,
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
logic [4:0] readRequestPrev;
logic [4:0] writeRequestPrev;
logic reset_ah;

assign reset_ah = ~reset;
assign DataToCPUs = fromTristate;
enum logic [5:0] {
	halted,
	updateQueue,
	incrQueue,
	read_0_0,
	read_0_1,
	read_1_0,
	read_1_1,
	read_2_0,
	read_2_1,
	read_3_0,
	read_3_1,
	read_4_0,
	read_4_1,
	write_0_0,
	write_0_1,
	write_1_0,
	write_1_1,
	write_2_0,
	write_2_1,
	write_3_0,
	write_3_1,
	write_4_0,
	write_4_1,
	done_0,
	done_1,
	done_2,
	done_3,
	done_4,
	done_0_wait,
	done_1_wait,
	done_2_wait,
	done_3_wait,
	done_4_wait,
	wait_all

} state, next_state;


/* State incrementer */
always_ff @ (posedge clk or posedge reset_ah)
    begin : Assign_Next_State
        if (reset_ah) 
            state <= halted;
        else 
            state <= next_state;
    end

assign SRAM_CE = (state == halted)? 1'b1 : 1'b0;

/* next state logic */
always_comb begin
	next_state = state;
	
	
	case ( state )
		halted: begin
			if ( run )
				next_state = updateQueue;
		end
		updateQueue: begin
			next_state = incrQueue;
		end
		incrQueue: begin
			unique case ( first_next )
				3'd0: begin
					if (writeRequest[0])
						next_state = write_0_0;
					else if (readRequest[0])
						next_state = read_0_0;
				end
				3'd1: begin
					if (writeRequest[1])
						next_state = write_1_0;
					else if (readRequest[1])
						next_state = read_1_0;
				end
				3'd2: begin
					if (writeRequest[2])
						next_state = write_2_0;
					else if (readRequest[2])
						next_state = read_2_0;
				end
				3'd3: begin
					if (writeRequest[3])
						next_state = write_3_0;
					else if (readRequest[3])
						next_state = read_3_0;
				end
				3'd4: begin
					if (writeRequest[4])
						next_state = write_4_0;
					else if (readRequest[4])
						next_state = read_4_0;
				end
				default: begin
					next_state = updateQueue;
				end
			endcase
		end
		
		read_0_0: 
			next_state = read_0_1;
		read_0_1:
			next_state = done_0;
		read_1_0:
			next_state = read_1_1;
		read_1_1:
			next_state = done_1;
		read_2_0:
			next_state = read_2_1;
		read_2_1:
			next_state = done_2;
		read_3_0:
			next_state = read_3_1;
		read_3_1:
			next_state = done_3;
		read_4_0:
			next_state = read_4_1;
		read_4_1:
			next_state = done_4;
		write_0_0:
			next_state = write_0_1;
		write_0_1:
			next_state = done_0;
		write_1_0:
			next_state = write_1_1;
		write_1_1:
			next_state = done_1;
		write_2_0:
			next_state = write_2_1;
		write_2_1:
			next_state = done_2;
		write_3_0:
			next_state = write_3_1;
		write_3_1:
			next_state = done_3;
		write_4_0:
			next_state = write_4_1;
		write_4_1:
			next_state = done_4;
		done_0:
			next_state = done_0_wait;
		done_1:
			next_state = done_1_wait;
		done_2:
			next_state = done_2_wait;
		done_3:
			next_state = done_3_wait;
		done_4:
			next_state = done_4_wait;
		done_0_wait:
			next_state = wait_all;
		done_1_wait:
			next_state = wait_all;
		done_2_wait:
			next_state = wait_all;
		done_3_wait:
			next_state = wait_all;
		done_4_wait:
			next_state = wait_all;
		wait_all:
			next_state = updateQueue;
	
	endcase

end

/* control logic */
always_ff @ (posedge clk) begin
	SRAM_WE = 1'b1;
	SRAM_RE = 1'b1;
	addressToSRAM = 16'hffff;
	toTristate = 16'hffff;
	requestDone = 5'b00000;
	
	unique case (state)
		halted: begin
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
			readRequestPrev = 5'b0;
			writeRequestPrev = 5'b0;
		end
		
		updateQueue: begin
			first_next = second;
			second_next = third;
			third_next = fourth;
			fourth_next = fifth;
			fifth_next = 3'b111;
			
			/******************
			 * QUEUE EMPLACER *
			 ******************/	 
			 
			 if ( ((readRequestPrev[4] != readRequest[4]) && (readRequest[4] != 1'b0 )) ||
					((writeRequestPrev[4] != writeRequest[4]) && (writeRequest[4] != 1'b0 )) ) begin
	
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
			
			if ( ((readRequestPrev[3] != readRequest[3]) && (readRequest[3] != 1'b0 )) ||
					((writeRequestPrev[3] != writeRequest[3]) && (writeRequest[3] != 1'b0 )) ) begin
	
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
			
			if ( ((readRequestPrev[2] != readRequest[2]) && (readRequest[2] != 1'b0 )) ||
					((writeRequestPrev[2] != writeRequest[2]) && (writeRequest[2] != 1'b0 )) ) begin
	
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
			
			if ( ((readRequestPrev[1] != readRequest[1]) && (readRequest[1] != 1'b0 )) ||
					((writeRequestPrev[1] != writeRequest[1]) && (writeRequest[1] != 1'b0 )) ) begin
	
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
			
			if ( ((readRequestPrev[0] != readRequest[0]) && (readRequest[0] != 1'b0 )) ||
					((writeRequestPrev[0] != writeRequest[0]) && (writeRequest[0] != 1'b0 )) ) begin
	
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
			
			readRequestPrev = readRequest;
			writeRequestPrev = writeRequest;
		end // end halted
		
		incrQueue: begin
			first = first_next;
			second = second_next;
			third = third_next;
			fourth = fourth_next;
			fifth = fifth_next;
		end
		read_0_0: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR0;
		end
		read_0_1: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR0;
		end
		read_1_0: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR1;
		end
		read_1_1: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR1;
		end
		read_2_0: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR2;
		end
		read_2_1: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR2;
		end
		read_3_0: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR3;
		end
		read_3_1:
		 begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR3;
		end
		read_4_0:
		 begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR4;
		end
		read_4_1: begin
			SRAM_RE = 1'b0;
			addressToSRAM = ADDR4;
		end
		write_0_0: begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR0;
			toTristate = DATA0;
		end
		write_0_1:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR0;
			toTristate = DATA0;
		end
		write_1_0:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR1;
			toTristate = DATA1;
		end
		write_1_1:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR1;
			toTristate = DATA1;
		end
		write_2_0:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR2;
			toTristate = DATA2;
		end
		write_2_1:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR2;
			toTristate = DATA2;
		end
		write_3_0:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR3;
			toTristate = DATA3;
		end
		write_3_1:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR3;
			toTristate = DATA3;
		end
		write_4_0:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR4;
			toTristate = DATA4;
		end
		write_4_1:begin
			SRAM_WE = 1'b0;
			addressToSRAM = ADDR4;
			toTristate = DATA4;
		end
		done_0: begin
			requestDone = 5'b00001;
			readRequestPrev[0] = 1'b0;
			
		end
		done_1: begin
			requestDone = 5'b00010;
			readRequestPrev[1] = 1'b0;
			
		end
		done_2: begin
			requestDone = 5'b00100;
			readRequestPrev[2] = 1'b0;
			
			end
		done_3: begin
			requestDone = 5'b01000;
			readRequestPrev[3] = 1'b0;
			
			end
		done_4: begin
			requestDone = 5'b10000;
			readRequestPrev[4] = 1'b0;
			
			end
		done_0_wait: begin 
			writeRequestPrev[0] = 1'b0;
			end
		done_1_wait: begin 
			writeRequestPrev[1] = 1'b0;
			end
		done_2_wait: begin 
			writeRequestPrev[2] = 1'b0;
			end
		done_3_wait: begin 
			writeRequestPrev[3] = 1'b0;
			end
		done_4_wait: begin 
			writeRequestPrev[4] = 1'b0;
			end
		wait_all: ;
	
	endcase



end
endmodule