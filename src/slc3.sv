//------------------------------------------------------------------------------
// Company: 		 UIUC ECE Dept.
// Engineer:		 Stephen Kempf
//
// Create Date:    
// Design Name:    ECE 385 Lab 6 Given Code - SLC-3 top-level (External SRAM)
// Module Name:    SLC3
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 09-22-2015 
//    Revised 02-13-2017 
//    Spring 2017 Distribution
//
//------------------------------------------------------------------------------


module slc3(
	input logic [15:0] S,
	input logic	Clk, Reset, Run, Continue,
	input logic [15:0] from_PC_X,
	input logic Ready1,	// from slave
	input logic Ready2,	// from slave
	input logic Ready3,	// from slave
	input logic Ready4,	// from slave
	input logic fromCPU_SEL,
	input logic [2:0] CPU_ID,
	input logic memReady,
	input logic [15:0] Data_from_SRAM,
	output logic CPU_READY,
	output logic [15:0] LED,
	output logic [15:0] from_PC_1,
	output logic [15:0] from_PC_2,
	output logic [15:0] from_PC_3,
	output logic [15:0] from_PC_4,
	output logic [3:0] CPU_SEL,
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
	output logic CE, UB, LB, OE, WE,
	output logic [19:0] ADDR,
	output logic [15:0] Data_to_SRAM,
	output logic [5:0] State
);

/*
	CE: Chip enable. When active, allows read/write operations on memory (active low)
	UB: Upper byte enable (active low)
	LB: Lower byte enable (active low)
	OE: Output enable. When active, RAM chips will drive output on selected banks of selected chips (active low)
	WE: Write enable. When active, orders writes to selected banks of selected chips. Active low. Priority over OE.
*/

// Declaration of push button active high signals	
logic Reset_ah, Continue_ah, Run_ah;

// An array of 4-bit wires to connect the hex_drivers efficiently to wherever we want
// For Week 1, they will directly be connected to the IR register
// For Week 2, they will be patched into the MEM2IO module so that Memory-mapped IO can take place
logic [3:0][3:0] hex_4;


logic [15:0] fromMAR, fromIR, fromPC_PlusOne, from_BUS, fromMARMUX, fromPC, fromALU, fromMDR;

// Internal connections
logic BEN;
logic LD_MAR, LD_MDR, LD_IR, LD_BEN, LD_CC, LD_REG, LD_PC, LD_LED;
logic GatePC, GateMDR, GateALU, GateMARMUX;
logic [1:0] PCMUX, ADDR2MUX, ALUK;
logic DRMUX, SR1MUX, SR2MUX, ADDR1MUX;
logic MIO_EN;
logic [15:0] fromMEM2IO;
logic [15:0] busLine;
logic [15:0] fromPCMUX, fromMDRMUX;
logic [15:0] fromIR_SEXT_4_0, fromIR_SEXT_5_0, fromIR_SEXT_8_0, fromIR_SEXT_10_0;
logic isNeg, isZero, isPos;
logic shouldBranch;

wire [15:0] fromSR2MUX;
wire [15:0] fromSR2;
wire [15:0] fromADDR2MUX;
wire [15:0] fromADDR1MUX;
wire [15:0] fromSR1;
wire [2:0] SR2select;
wire [2:0] fromDRMUX, fromSR1MUX;
wire fromN, fromZ, fromP;


// Connect MAR to ADDR, which is also connected as an input into MEM2IO
//	MEM2IO will determine what gets put onto Data_CPU (which serves as a potential
//	input into MDR)
assign ADDR = { 4'b0000, fromMAR }; //Note, our external SRAM chip is 1Mx16, but address space is only 64Kx16
assign MIO_EN = ~OE;
assign Reset_ah = ~Reset;
assign Continue_ah = ~Continue;
assign Run_ah = ~Run;
assign SR2select = fromIR[2:0];

// LED
always_comb 
begin
	if(LD_LED)
		LED = fromIR[15:0];
	else
		LED = 12'b0;
end

// Remove the following assignments for Week 2
/*
assign hex_4[3][3:0] = fromIR[15:12];
assign hex_4[2][3:0] = fromIR[11:8];
assign hex_4[1][3:0] = fromIR[7:4];
assign hex_4[0][3:0] = fromIR[3:0];
*/
// HexDriver hex_drivers[3:0] (hex_4, {HEX3, HEX2, HEX1, HEX0});
// This works thanks to http://stackoverflow.com/questions/1378159/verilog-can-we-have-an-array-of-custom-modules

														/******************
														 * PC_X REGISTERS *
														 ******************/

logic LD_PC1;
logic LD_PC2;
logic LD_PC3;
logic LD_PC4;
		 
reg16 PC_1(.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_PC1), .dIn(busLine), .dOut(from_PC_1));
reg16 PC_2(.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_PC2), .dIn(busLine), .dOut(from_PC_2));
reg16 PC_3(.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_PC3), .dIn(busLine), .dOut(from_PC_3));
reg16 PC_4(.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_PC4), .dIn(busLine), .dOut(from_PC_4));

														/************************
														 * CPU SELECT REGISTERS *
														 ************************/
logic LD_CPU_SEL;

wire [15:0] CPU_SEL_outWire;
assign CPU_SEL = CPU_SEL_outWire[3:0];

reg16 CPU_SEL_o(.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_CPU_SEL), .dIn( {12'b0,fromIR[3:0]} ), .dOut(CPU_SEL_outWire));

														/*******************
														 * READY FLIP FLOP *
														 *******************/
														 
				  
logic LD_SET_READY;
logic SET_READY_DATA;
DflipFlop READY_o ( .Clk(Clk), .Reset(Reset_ah), .Load(LD_SET_READY), .D(SET_READY_DATA), .Q(CPU_READY));
														/**********
														 * PC MUX *
														 **********/
// MUX that control the PC Mux
_16BIT_4to1MUX o_PCMUX( .dIn0(fromPC_PlusOne), .dIn1(busLine), .dIn2(fromMARMUX), .dIn3(from_PC_X), .select(PCMUX), .dOut(fromPCMUX));



					 

														/*******************
														 * PROGRAM COUNTER *
														 *******************/
														 
// PC implementation
ProgramCounter ProgramCounter(.toPC(fromPCMUX), .LD_PC(LD_PC), .PC(fromPC), .Clk(Clk), .Reset(Reset_ah));
assign fromPC_PlusOne = fromPC + 1;

														/***********************************
														 * MAR MUX ( A.K.A ADDRESS ADDER ) *
														 ***********************************/
														 
assign fromMARMUX = fromADDR2MUX + fromADDR1MUX;
														 
														/************
														 * ADDR2MUX *
														 ************/
_16BIT_4to1MUX o_ADDR2MUX ( .dIn0(16'b0), .dIn1(fromIR_SEXT_5_0), .dIn2(fromIR_SEXT_8_0), .dIn3(fromIR_SEXT_10_0), .select(ADDR2MUX), .dOut(fromADDR2MUX));

														/************
														 * ADDR1MUX *
														 ************/
wire [1:0] w1;
assign w1[1] = 0;
assign w1[0] = ADDR1MUX;
_16BIT_4to1MUX o_ADDR1MUX ( .dIn0(fromPC), .dIn1(fromSR1), .dIn2(16'b0), .dIn3(16'b0), .select( w1 ), .dOut(fromADDR1MUX));

														/*********
														 * DRMUX *
														 *********/
// Note: the "o_" is to just denote that it's an object. This is done to prevent clash with variable names
_3BIT_2to1MUX o_DRMUX (.dIn0(fromIR[11:9]), .dIn1(3'b111), .select(DRMUX), .dOut(fromDRMUX) );


														/**********
														 * SR1MUX *
														 **********/
														 
_3BIT_2to1MUX o_SR1MUX( .dIn0(fromIR[11:9]), .dIn1(fromIR[8:6]), .select(SR1MUX), .dOut(fromSR1MUX));


														/*****************
														 * REGISTER FILE *
														 *****************/

regFile regFile( .dIn(busLine), .DRselect(fromDRMUX), .SR1select(fromSR1MUX), .SR2select(SR2select),
					  .LD_REG(LD_REG), .Clk(Clk), .Reset(Reset_ah), .SR2OUT(fromSR2), .SR1OUT(fromSR1));
					  
					  
														/**********
														 * SR2MUX *
														 **********/
assign fromSR2MUX = SR2MUX ? fromIR_SEXT_4_0 : fromSR2;
//_16BIT_2to1MUX o_SR2MUX( .dIn0(fromIR_SEXT_4_0), .dIn1(fromSR2), .select(SR2MUX), .dOut(fromSR2MUX));
	
														/*******
														 * ALU *
														 *******/
ALU o_ALU( .B(fromSR2MUX), .A(fromSR1), 
		.ALUK(ALUK), .ALUout(fromALU) );

														/**************
														 * BUS MODULE *
														 **************/
// MUX that control the main 16-bit busmux
//BusMux BusMux (.GatePC, .GateMDR, .GateALU, .GateMARMUX, .fromMARMUX(fromMARMUX), .fromPC(fromPC), .fromALU(fromALU), .fromMDR(fromMDR)); //????? s
BusMUX BusMux (.*, .busOut(busLine) );



														

														/*************
														 * NZP LOGIC *
														 *************/
														 
assign isNeg = busLine[15] ? 1'b1 : 1'b0;
assign isPos = ~isNeg & ~isZero;
always_comb begin
	case (busLine)
		16'b0000000000000000: isZero = 1;
		default : isZero = 0;
	endcase
end

														/*******
														 * NZP *
														 *******/
DflipFlop o_N ( .Clk(Clk), .Reset(Reset_ah), .Load(LD_CC), .D(isNeg), .Q(fromN) );
DflipFlop o_Z ( .Clk(Clk), .Reset(Reset_ah), .Load(LD_CC), .D(isZero), .Q(fromZ) );
DflipFlop o_P ( .Clk(Clk), .Reset(Reset_ah), .Load(LD_CC), .D(isPos), .Q(fromP) );

														/****************
														 * BRANCH LOGIC *
														 ****************/

assign shouldBranch = (fromIR[11] & fromN) | (fromIR[10] & fromZ) | (fromIR[9] & fromP);


														/*******************
														 * BRANCH REGISTER *
														 *******************/
DflipFlop o_BEN (.Clk(Clk), .Reset(Reset_ah), .Load(LD_BEN), .D(shouldBranch),
              .Q(BEN));

														/*****************
														 * STATE MACHINE *
														 *****************/
wire toCEsync, toUBsync, toLBsync, toOEsync, toWEsync;
														 
// State machine and control signals
ISDU state_controller(
	.*, .Reset(Reset_ah), .Run(Run_ah), .Continue(Continue_ah),
	.Opcode(fromIR[15:12]), .IR_5(fromIR[5]), .IR_11(fromIR[11]),
	.ParallelOpcode(fromIR[11:9]),
	.CPUX(fromIR[3:0]),
	.CPUID(CPU_ID),
	.Mem_CE(toCEsync), .Mem_UB(toUBsync), .Mem_LB(toLBsync), .Mem_OE(toOEsync), .Mem_WE(toWEsync),
	.state_o(State)
);

// Synchronize the memory signals
sync CE_sync( .Clk(Clk), .Reset(Reset_ah), .d(toCEsync), .q(CE) );
sync UB_sync( .Clk(Clk), .Reset(Reset_ah), .d(toUBsync), .q(UB) );
sync LB_sync( .Clk(Clk), .Reset(Reset_ah), .d(toLBsync), .q(LB) );
sync OE_sync( .Clk(Clk), .Reset(Reset_ah), .d(toOEsync), .q(OE) );
sync WE_sync( .Clk(Clk), .Reset(Reset_ah), .d(toWEsync), .q(WE) );


														/***********
														 * MDR MUX *
														 ***********/

assign fromMDRMUX = MIO_EN ? Data_from_SRAM : busLine;

														/*******************
														 * MAR, MDR and IR *
														 *******************/
														 
assign Data_to_SRAM = fromMDR;

reg16 o_MAR ( .Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_MAR), .dIn(busLine), .dOut(fromMAR));
reg16 o_MDR (.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_MDR), .dIn(fromMDRMUX), .dOut(fromMDR));											 
reg16 o_IR (.Clk(Clk), .Reset(Reset_ah), .LD_REG(LD_IR), .dIn(busLine), .dOut(fromIR));

														/**********
														 * IRSEXT *
														 **********/
												// Instruction register sign extend

//assign fromIRSEXT_4_0 = fromIR[4] ? {11{1'b1},fromIR[4:0]} : {11{1'b0},fromIR[4:0]};
assign fromIR_SEXT_4_0 = 16'(signed'(fromIR[4:0]));
//assign fromIRSEXT_5_0 = fromIR[5] ? {10{1'b1},fromIR[5:0]} : {10{1'b0},fromIR[5:0]};
assign fromIR_SEXT_5_0 = 16'(signed'(fromIR[5:0]));
//assign fromIRSEXT_8_0 = fromIR[8] ? {7{1'b1},fromIR[8:0]} : {7{1'b0},fromIR[8:0]};
assign fromIR_SEXT_8_0 = 16'(signed'(fromIR[8:0]));
//assign fromIRSEXT_10_0 = fromIR[10] ? {5{1'b1},fromIR[10:0]} : {5{1'b0},fromIR[10:0]};
assign fromIR_SEXT_10_0 = 16'(signed'(fromIR[10:0]));

// An example of instantiating the test_memory. Do not instantiate it here.
// Read the instructions in the header of test_memory.sv about how to use it.
// Test memory is only for simulation, and should NOT be included when circuit is tested on FPGA board.
// Otherwise, the circuit will not function correctly.
/*
test_memory test_memory0(
	.Clk(Clk), .Reset(~Reset),
	.I_O(Data), .A(ADDR),
	.*
);
*/

HexDriver        Hex0(
                        .In0(hex_4[0]),
                        .Out0(HEX0) );
	HexDriver        Hex1 (
                        .In0(hex_4[1]),
                        .Out0(HEX1) );
	HexDriver        Hex2 (
                        .In0(hex_4[2]),
                        .Out0(HEX2) );
	HexDriver        Hex3 (
                        .In0(hex_4[3]),
                        .Out0(HEX3) );
	HexDriver        Hex4(
                        .In0(fromPC[3:0]),
                        .Out0(HEX4) );
	HexDriver        Hex5 (
                        .In0(fromPC[7:4]),
                        .Out0(HEX5) );
	HexDriver        Hex6 (
                        .In0(fromPC[11:8]),
                        .Out0(HEX6) );
	HexDriver        Hex7 (
                        .In0(fromPC[15:12]),
                        .Out0(HEX7) );

/*							
	HexDriver        Hex0(
                        .In0(fromPC[3:0]),
                        .Out0(HEX0) );
	HexDriver        Hex1 (
                        .In0(fromPC[7:4]),
                        .Out0(HEX1) );
	HexDriver        Hex2 (
                        .In0(fromPC[11:8]),
                        .Out0(HEX2) );
	HexDriver        Hex3 (
                        .In0(fromPC[15:12]),
                        .Out0(HEX3) );
	HexDriver        Hex4 (
                        .In0(hex_4[0]),
                        .Out0(HEX4) );
	HexDriver        Hex5 (
                        .In0(hex_4[1]),
                        .Out0(HEX5) );
	HexDriver        Hex6 (
                        .In0(hex_4[2]),
                        .Out0(HEX6) );
	HexDriver        Hex7 (
                        .In0(hex_4[3]),
                        .Out0(HEX7) );
*/

endmodule
