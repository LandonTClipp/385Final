//------------------------------------------------------------------------------
// Company: 		 UIUC ECE Dept.
// Engineer:		 Stephen Kempf
//
// Create Date:    17:44:03 10/08/06
// Design Name:    ECE 385 Lab 6 Given Code - Incomplete ISDU
// Module Name:    ISDU - Behavioral
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 02-13-2017
//    Spring 2017 Distribution
//------------------------------------------------------------------------------


module ISDU ( 	input logic			Clk, 
                        			Reset,
									Run,
									Continue,
									
				input logic[3:0] 	Opcode, 
				input logic[2:0]	ParallelOpcode, // ***NEW***
				input logic     	IR_5,
				input logic     	IR_11,
				input logic 		BEN,
				/* I'm getting tired of referring to IR in a piecemeal fasion
					so I'm just including the whole signal.
				*/
				input logic[15:0]	fromIR,
				input logic [2:0] CPUID,
				// ***NEW*** // Ready signals from compute nodes
				input logic			Ready1,	// From slave 1
				input logic			Ready2,	// from slave 2
				input logic			Ready3,	// from slave 3
				input logic			Ready4,	// from slave 4
				input logic[3:0]	CPUX, 	// value from IR that pauses execution until slaves send ready signal. MSB is PC_1, LSB is PC_4 // IR[3:0]
				input logic fromCPU_SEL, 
				input logic memReady,
				// pass value of CPU_SEL[1] for the first CPU, etc. 
		
				output logic 		LD_MAR,
									LD_MDR,
									LD_IR,
									LD_BEN,
									LD_CC,
									LD_REG,
									LD_PC,
									LD_LED, // for PAUSE instruction
									LD_PC1, // ***NEW***
									LD_PC2, // ***NEW***
									LD_PC3, // ***NEW***
									LD_PC4, // ***NEW***
									LD_CPU_SEL,		// 4-bit CPU select register (only for master)
									LD_SET_READY,	// control signal for READY flip flop
									SET_READY_DATA,		// The data bit going to READY flip flop
									
									
				output logic 		GatePC,
									GateMDR,
									GateALU,
									GateMARMUX,
									
				output logic [1:0] 	PCMUX,
				output logic        DRMUX,
									SR1MUX,
									SR2MUX,
									ADDR1MUX,
				output logic [1:0] 	ADDR2MUX,
									ALUK,
				  
				output logic 		Mem_CE,
									Mem_UB,
									Mem_LB,
									Mem_OE,
									Mem_WE,
				output logic [5:0] state_o
				);
assign Mem_CE = 1'b0;
assign Mem_UB = 1'b0;
assign Mem_LB = 1'b0;

		
// 24 states in total, 5 bits for states
    enum logic [5:0] {Halted = 6'd0, 
							
							S_18 = 6'd1, 
							S_33_1 = 6'd2, 
							S_33_2 = 6'd3, 
							S_35 = 6'd4, 
							S_32 = 6'd5, 
							S_01 = 6'd6,
							S_02 = 6'd7,
							S_05 = 6'd8,
							S_09 = 6'd9,
							S_06 = 6'd10,
							S_25_1 = 6'd11, 
							S_25_2 = 6'd12,
							S_27 = 6'd13,
							S_07 = 6'd14,
							S_23 = 6'd15,
							S_16_1 = 6'd16, 
							S_16_2 = 6'd17,
							S_00 = 6'd18,
							S_22 = 6'd19,
							S_12 = 6'd20,
							S_04 = 6'd21,
							S_21 = 6'd22, 
							// ***NEW***		
							S_36 = 6'd23,
							S_37 = 6'd24, 
							S_37_1 = 6'd25, 
							S_37_2 = 6'd26,
							S_38 = 6'd27,
							S_39 = 6'd28,
							S_40 = 6'd29,
							S_41_1 = 6'd30,
							S_41_2 = 6'd31,
							S_42 = 6'd32,
							S_43 = 6'd33,
							S_44 = 6'd34
					}   State, Next_state;   // Internal state logic
					
assign state_o = State;
	    
    always_ff @ (posedge Clk)
    begin : Assign_Next_State
        if (Reset) 
            State <= Halted;
        else 
            State <= Next_state;
    end
   
	always_comb
    begin 
    	// Default next state is staying at current state
	   Next_state = State;
		
        case (State)
            Halted : 
	            if (Run) 
					Next_state = S_18;
            S_18 : 
                Next_state = S_33_1;
					 
            // Any states involving SRAM require more than one clock cycles.
            // The exact number will be discussed in lecture.
            S_33_1 : begin
					if ( ~memReady )
						Next_state = S_33_1;
					else
						Next_state = S_33_2;
				end
            S_33_2 : 
                Next_state = S_35;
            S_35 : 
					 Next_state = S_32;
            //    Next_state <= PauseIR1;
            // PauseIR1 and PauseIR2 are only for Week 1 such that TAs can see 
            // the values in IR. They should be removed in Week 2
            
            S_32 : 
				case (Opcode)
					 4'b0001 : 
					   Next_state = S_01; // ADD
					 4'b0101 : 
						Next_state = S_05; // AND
					 4'b1001 : 
						Next_state = S_09; // NOT
					 4'b0000 : 
						Next_state = S_00; // BR
					 4'b1100 : 
						Next_state = S_12; // JMP	
					 4'b0100 : 
						Next_state = S_04; // JSR	
					 4'b0110 : 
						Next_state = S_06; // LDR
					 4'b0010 :
						Next_state = S_02;
				    4'b0111 : 
						Next_state = S_07; // STR		
					 4'b1101 : // ***NEW***
						Next_state = S_36; // Decode parallel instructions 
					default : 
					    Next_state = S_18;
				endcase
				
            S_01 : 
					Next_state = S_18;
				S_02:
					Next_state = S_25_1;
				S_05 : 
					Next_state = S_18;
				S_09 : 
					Next_state = S_18;	
				S_06 :
					Next_state = S_25_1;
				S_25_1 : begin
					if ( ~memReady)
						Next_state = S_25_1;
					else
						Next_state = S_25_2;
				end
				S_25_2 :
					Next_state = S_27;
				S_27 :
					Next_state = S_18;
					
				S_07 : 
					Next_state = S_23;
				S_23 : 
					Next_state = S_16_1;
				S_16_1 : begin
					if ( ~memReady )
						Next_state = S_16_1;
					else
						Next_state = S_16_2;	
				end
				S_16_2 :
					Next_state = S_18;
				S_04 : 
					Next_state = S_21;
				S_21 :
					Next_state = S_18;
				S_12 :
					Next_state = S_18;
				S_00 :
					if (BEN) 
						Next_state = S_22;
					else 
						Next_state = S_18;
				S_22 :
					Next_state = S_18;
					
				S_36 : // ***NEW***
				case(ParallelOpcode) 
					3'b000 : // PC_INIT
						Next_state = S_37_1;
					3'b001 : // CPU_SEL
						Next_state = S_38;
					3'b010 : // SYNC
						Next_state = S_39;
					3'b011 : // READY
						Next_state = S_40;
					3'b100 : // WAIT
						Next_state = S_41_1;
					3'b101 : //INTR_PC
						Next_state = S_42;
					3'b110 : // BR_CPUID
						Next_state = S_43;
					default:
						Next_state = S_18;
				endcase
				
				S_37_1 :
					Next_state = S_37_2;
				S_37_2:
					Next_state = S_18;
				S_38 :
					Next_state = S_18;
				S_39 :
					if (CPUX != { Ready1, Ready2, Ready3, Ready4} ) // CPUX != R1R2R3R4
						Next_state = S_39;
					else 
						Next_state = S_18; // ***NEW***
				S_40 :
					Next_state = S_18;
				S_41_1 :
				begin
					if (!fromCPU_SEL)
						Next_state = S_41_1;
					else 
						Next_state = S_41_2;
				end
				S_41_2:
					Next_state = S_18;
				S_42 :
					Next_state = S_18; 
				S_43 :
				begin
					if ( CPUID == fromIR[8:6])
						Next_state = S_44;
					else
						Next_state = S_18;
				end
				S_44:
					Next_state = S_18;
					
			default : ;
	     endcase
    end
   
    always_comb
    begin 
        // default controls signal values; within a process, these can be
        // overridden further down (in the case statement, in this case)
	    LD_MAR = 1'b0;
	    LD_MDR = 1'b0;
	    LD_IR = 1'b0;
	    LD_BEN = 1'b0;
	    LD_CC = 1'b0;
	    LD_REG = 1'b0;
	    LD_PC = 1'b0;
	    LD_LED = 1'b0;
		 LD_SET_READY = 1'b0;
		 SET_READY_DATA = 1'b0;
		 LD_PC1 = 1'b0;
		 LD_PC2 = 1'b0;
		 LD_PC3 = 1'b0;
		 LD_PC4 = 1'b0;
		 LD_CPU_SEL = 1'b0;
		 
	    GatePC = 1'b0;
	    GateMDR = 1'b0;
	    GateALU = 1'b0;
	    GateMARMUX = 1'b0;
		 
		 ALUK = 2'b00;
		 
	    PCMUX = 2'b00;
		 
	    DRMUX = 1'b0;
	    SR1MUX = 1'b0;
	    SR2MUX = 1'b0;
	    ADDR1MUX = 1'b0;
	    ADDR2MUX = 2'b00;
		 
	    Mem_OE = 1'b1;		// Memory read enable. Active low.
	    Mem_WE = 1'b1;		// Memory write enable. Active low.
		
		// Assign control signals based on current state
	    unique case (State)
			Halted: ;
			// Load MAR with contents of PC
			S_18 : 
				begin 
					GatePC = 1'b1;		// Load PC onto bus
					LD_MAR = 1'b1;		// Set MAR to read from bus
					Mem_OE = 1'b0;			// Enable reading from memory
				end
				
			// Perform memory access with MAR
			S_33_1 : begin
				Mem_OE = 1'b0;
				LD_MDR = 1'b1;
			end
				
			// MDR<-M[MAR]	
			S_33_2 : 
				begin 
					// NOTE: LD_MDR is moved back to S_33_1 for the parallel LC-3 implementation for synchronization purposes
					//LD_MDR = 1'b1;		// Load MDR with output of memory
            end
         S_35 : 
             begin 
					GateMDR = 1'b1;	// Put MDR onto bus
					LD_IR = 1'b1;		// Set the IR to load
					PCMUX = 2'b00;		// Set input to PC as PC+1
					LD_PC = 1'b1;		// PC<-PC+1
             end
			
			S_32 : 
				LD_BEN = 1'b1;
				
			// ADD(i) 	
			S_01 : 
         begin
				SR1MUX = 1'b1;
				SR2MUX = IR_5;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
			end

			// LD
			S_02: begin
				ADDR2MUX = 2'b10;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
			end
         // AND(i)
			S_05 : 
         begin
				SR1MUX = 1'b1;
				SR2MUX = IR_5;
				ALUK = 2'b01;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
			end
			
			// NOT
			S_09 : 
         begin
				SR1MUX = 1'b1;
				ALUK = 2'b10;
				GateALU = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
			end
			
			// LDR
			S_06 :
			begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1; // choose baseR
				ADDR2MUX = 2'b01;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
				Mem_OE = 1'b0;
			end
			// Perform memory access with MAR
			S_25_1 : begin
				Mem_OE = 1'b0;
				LD_MDR = 1'b1;
			end
			// MDR<-M[MAR]	
			S_25_2 : begin end
				// LD_MDR moved back one state for the purposes of synchronization
				//LD_MDR = 1'b1;		// Load MDR with output of memory
			S_27:
			begin
			   LD_CC = 1'b1;
				LD_REG = 1'b1;
				GateMDR = 1'b1;
			end
		
			// STR
			S_07 :
			begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1; // choose baseR
				ADDR2MUX = 2'b01;
				GateMARMUX = 1'b1;
				LD_MAR = 1'b1;
			end
			// Perform memory access with MAR
			S_23:
			begin
				ALUK = 2'b11;
				GateALU = 1'b1;
				LD_MDR = 1'b1;
				Mem_WE = 1'b0;
			end
			// ???
			S_16_1 : 
				Mem_WE = 1'b0;
			// 
			S_16_2 : ;
			// JSR
			S_04 :
			begin
				GatePC = 1'b1;
				DRMUX = 1'b1; // destination R7
				LD_REG = 1'b1;
			end
			S_21 : 
			begin
				ADDR2MUX = 2'b11; // choose IR[10:0]
				PCMUX = 2'b10; 	// choose address adder
				LD_PC = 1'b1;
			end
			// JMP
			S_12 :
			begin
				SR1MUX = 1'b1;
				ADDR1MUX = 1'b1;
				ADDR2MUX = 2'b00;
				PCMUX = 2'b10;		// Load PC from bus
				LD_PC = 1'b1;
			end
			// BR
			// S_00 taken care of. S_22 is the case where branch is desired.
			S_22 :
			begin
				ADDR2MUX = 2'b10; // choose IR[8:0]
				PCMUX = 2'b10; 	// choose address adder
				LD_PC = 1'b1;
			end
			
			// ***NEW***
			S_36 : 
			begin
				// nothing?
			end
			
			// PC_init
			
			S_37_1 :	begin
				SR1MUX = 1'b1;
				ALUK = 2'b11;
				GateALU = 1'b1;
			end
			S_37_2 : begin
				GateALU = 1'b1;
				ALUK = 2'b11;
				SR1MUX = 1'b1;
				LD_PC1 = CPUX[3];
				LD_PC2 = CPUX[2];
				LD_PC3 = CPUX[1];
				LD_PC4 = CPUX[0];
			end
			S_38 :
				LD_CPU_SEL = 1'b1;
				
			S_39 :
			begin
				// nothing?
			end
			S_40 :
			begin
				LD_SET_READY = 1'b1;
				SET_READY_DATA = 1'b1;
			end
			S_41_1 :
			begin
			end
			S_41_2 :
			begin
				LD_SET_READY = 1'b1;
				SET_READY_DATA = 1'b0;
			end
			S_42 :
			begin
				PCMUX = 2'b11;
				LD_PC = 1'b1;
			end	
			
			// BR_CPUID
			S_43:
			begin	
			end
			S_44:
			begin
				ADDR2MUX = 2'b01; // choose IR[5:0]
				PCMUX = 2'b10; 	// choose address adder
				LD_PC = 1'b1;
			end
			
			default : begin end
        endcase
    end 

 	// These should always be active

	
endmodule

