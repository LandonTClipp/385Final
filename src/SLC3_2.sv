//-------------------------------------------------------------------------
//      SLC3_2.sv                                                        --
//      Stephen Kempf                                                    --
//      Created  Spring 2006                                             --
//      Revised  3-22-2007                                               --
//              10-22-2013                                               --
//              03-04-2014                                               --
//                                                                       --
//      Spring 2015 Distribution                                         --
//                                                                       --
//      For use with ECE 385 Lab 8 (Test_Memory)                         --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------
// TO USE: Include this file in your project, and paste the following 2 lines
//   (uncommented) into whatever file needs to reference the functions &
//   constants included in this file, just after the usual library references:
//`include "SLC3_2.sv"
//import SLC3_2::*;

`ifndef _SLC3_2__SV 
`define _SLC3_2__SV

package SLC3_2;
  
   parameter op_ADD = 4'b0001; // opcode aliases
   parameter op_AND = 4'b0101;
   parameter op_NOT = 4'b1001;
   parameter op_BR  = 4'b0000;
   parameter op_JMP = 4'b1100;
   parameter op_JSR = 4'b0100;
   parameter op_LDR = 4'b0110;
   parameter op_STR = 4'b0111;
   parameter op_PAR = 4'b1101;
	
	// These are the 3-bit sub-opcodes for parallel instructions
	parameter op_PC_INIT = 3'b000;
	parameter op_CPU_SEL = 3'b001;
	parameter op_SYNC = 3'b010;
	parameter op_READY = 3'b011;
	parameter op_WAIT = 3'b100;
	parameter op_INTR_PC = 3'b101;
	parameter op_BR_CPUID = 3'b110;
	
   parameter NO_OP = 15'b0;   // "branch never" is a no op
  
   parameter R0 = 3'b000;      // register aliases
   parameter R1 = 3'b001;
   parameter R2 = 3'b010;
   parameter R3 = 3'b011;
   parameter R4 = 3'b100;
   parameter R5 = 3'b101;
   parameter R6 = 3'b110;
   parameter R7 = 3'b111;
  
   parameter p   = 3'b001;     // branch condition aliases
   parameter z   = 3'b010;
   parameter zp  = 3'b011;
   parameter n   = 3'b100;
   parameter np  = 3'b101;
   parameter nz  = 3'b110;
   parameter nzp = 3'b111;
 
   parameter outHEX = -1;
   parameter inSW = -1;
	
	function [15:0] opPC_INIT ( input [2:0] SR, input[3:0] PC_X );
      opPC_INIT[15:12] = op_PAR;
      opPC_INIT[11: 9] = op_PC_INIT;
      opPC_INIT[ 8: 6] = SR;
      opPC_INIT[ 5:4 ] = 2'b00;
      opPC_INIT[ 3: 0] = PC_X;
   endfunction
	
	function [15:0] opCPU_SEL ( input[3:0] imm4 );
      opCPU_SEL[15:12] = op_PAR;
      opCPU_SEL[11: 9] = op_CPU_SEL;
      opCPU_SEL[ 8: 4] = 5'b00000;
      opCPU_SEL[ 3: 0] = imm4;
   endfunction
	
	function [15:0] opSYNC ( input[3:0] CPUX_READY );
      opSYNC[15:12] = op_PAR;
      opSYNC[11: 9] = op_SYNC;
      opSYNC[ 8: 4] = 5'b00000;
      opSYNC[ 3: 0] = CPUX_READY;
   endfunction
	
	function [15:0] opREADY ( );
      opREADY[15:12] = op_PAR;
      opREADY[11: 9] = op_READY;
      opREADY[ 8: 0] = 9'b000000000;
   endfunction
	
	function [15:0] opBR_CPUID ( input [2:0] CPUID, input[5:0] PCoffset);
      opBR_CPUID[15:12] = op_PAR;
      opBR_CPUID[11: 9] = op_BR_CPUID;
		opBR_CPUID[8:6]   = CPUID;
      opBR_CPUID[ 5: 0] = PCoffset;
   endfunction
	
	function [15:0] opWAIT ( );
      opWAIT[15:12] = op_PAR;
      opWAIT[11: 9] = op_WAIT;
		opWAIT[8:0]   = 9'b000000000;
   endfunction
	
	function [15:0] opINTR_PC ( );
      opINTR_PC[15:12] = op_PAR;
      opINTR_PC[11: 9] = op_INTR_PC;
		opINTR_PC[8:0]   = 9'b000000000;
   endfunction
  
   function [15:0] opCLR ( input [2:0] DR );
      opCLR[15:12] = op_AND;
      opCLR[11: 9] = DR;
      opCLR[ 8: 6] = DR;
      opCLR[ 5   ] = 1'b1;
      opCLR[ 4: 0] = 5'b0;
   endfunction
	
   function [15:0] opAND ( input [2:0] DR, SR1, SR2 );
      opAND[15:12] = op_AND;
      opAND[11: 9] = DR;
      opAND[ 8: 6] = SR1;
      opAND[ 5: 3] = 3'b0;
      opAND[ 2: 0] = SR2;
   endfunction
  
   function [15:0] opANDi ( input [2:0] DR, SR, integer imm5 );
      opANDi[15:12] = op_AND;
      opANDi[11: 9] = DR;
      opANDi[ 8: 6] = SR;
      opANDi[ 5   ] = 1'b1;
      opANDi[ 4: 0] = imm5[4:0];
   endfunction
	
   function [15:0] opADD ( input [2:0] DR, SR1, SR2 );
      opADD[15:12] = op_ADD;
      opADD[11: 9] = DR;
      opADD[ 8: 6] = SR1;
      opADD[ 5: 3] = 3'b0;
      opADD[ 2: 0] = SR2;
   endfunction
  
   function [15:0] opADDi ( input [2:0] DR, SR, integer imm5 );
      opADDi[15:12] = op_ADD;
      opADDi[11: 9] = DR;
      opADDi[ 8: 6] = SR;
      opADDi[ 5   ] = 1'b1;
      opADDi[ 4: 0] = imm5[4:0];
   endfunction
  
   function [15:0] opINC ( input [2:0] DR );
      opINC[15:12] = op_ADD;
      opINC[11: 9] = DR;
      opINC[ 8: 6] = DR;
      opINC[ 5   ] = 1'b1;
      opINC[ 4: 0] = 1;
   endfunction
	
   function [15:0] opDEC ( input [2:0] DR );
      opDEC[15:12] = op_ADD;
      opDEC[11: 9] = DR;
      opDEC[ 8: 6] = DR;
      opDEC[ 5   ] = 1'b1;
      opDEC[ 4: 0] = -1;
   endfunction
	
   function [15:0] opNOT ( input [2:0] DR, SR );
      opNOT[15:12] = op_NOT;
      opNOT[11: 9] = DR;
      opNOT[ 8: 6] = SR;
      opNOT[ 5: 0] = 5'b1;
   endfunction
	
   function [15:0] opBR ( input [2:0] condition, integer PCoffset9 );
      opBR[15:12] = op_BR;
      opBR[11: 9] = condition;
      opBR[ 8: 0] = PCoffset9[8:0];
   endfunction
	
   function [15:0] opJMP ( input [2:0] BaseR );
      opJMP[15:12] = op_JMP;
      opJMP[11: 9] = 3'b0;
      opJMP[ 8: 6] = BaseR;
      opJMP[ 5: 0] = 6'b0;
   endfunction
	
   function [15:0] opRET ( );
      opRET[15:12] = op_JMP;
      opRET[11: 9] = 3'b0;
      opRET[ 8: 6] = R7;
      opRET[ 5: 0] = 6'b0;
   endfunction
	
   function [15:0] opJSR ( input integer PCoffset11 );
      opJSR[15:12] = op_JSR;
      opJSR[11   ] = 1'b1;
      opJSR[10: 0] = PCoffset11[10:0];
   endfunction
	
   function [15:0] opLDR ( input [2:0] DR, BaseR, integer offset6 );
      opLDR[15:12] = op_LDR;
      opLDR[11: 9] = DR;
      opLDR[ 8: 6] = BaseR;
      opLDR[ 5: 0] = offset6[5:0];
   endfunction
	
   function [15:0] opSTR ( input [2:0] SR, BaseR, integer offset6 );
      opSTR[15:12] = op_STR;
      opSTR[11: 9] = SR;
      opSTR[ 8: 6] = BaseR;
      opSTR[ 5: 0] = offset6[5:0];
   endfunction
	/*
   function [15:0] opPSE ( input [11:0] ledVect12 );
      opPSE[15:12] = op_PSE;
      opPSE[11: 0] = ledVect12;
   endfunction
	*/
	
	
endpackage

`endif 