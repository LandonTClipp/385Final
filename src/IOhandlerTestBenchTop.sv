module IOhandlerTestBenchTop(  input logic Clk, input logic reset, input logic [4:0]writeRequest, input logic [4:0] readRequest,
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
										output logic SRAM_WE_O,
										output logic SRAM_RE_O,
										output logic addressToSRAM_O,
										output logic [15:0] DataToCPUs,
										output logic [4:0] requestDone
										);
	/*
module IOhandler( input logic clk,
						input logic reset,
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
						
						inout logic [15:0] SRAMdata,
						
						output logic [15:0] addressToSRAM,
						output logic [15:0] DataToCPUs,
						// WE and RE are active LOW
						output logic SRAM_WE,
						output logic SRAM_RE,
						output logic [4:0] requestDone);
*/
wire [15:0] addressToSRAM;
wire [15:0] SRAMdata;
wire SRAM_WE;
wire SRAM_RE;
wire [15:0] fromTristate;
wire[15:0] toTristate;

assign SRAM_WE_O = SRAM_WE;
assign SRAM_RE_O = SRAM_RE;
assign addressToSRAM_O = addressToSRAM;
wire SRAM_CE;
wire run;

IOhandler topLevel( .clk(Clk), .reset(reset), .writeRequest(writeRequest), .readRequest(readRequest), 
						  .addressToSRAM(addressToSRAM),  .SRAM_WE, .SRAM_RE,
						  .requestDone(requestDone), .*
					  );
					  
tristate tristate_o( .Clk(Clk), .tristate_output_enable(~SRAM_WE), .Data_write(toTristate), .Data_read(fromTristate), .Data(SRAMdata));
					  
/*
module test_memory ( input          Clk,
                     input          Reset, 
                     inout  [15:0]  I_O,
                     input  [19:0]  A,
                     input          CE,
                                    UB,
                                    LB,
                                    OE,
                                    WE );*/
test_memory test_mem(.Clk(Clk), .Reset(reset), .I_O(SRAMdata), .A({4'b0000,addressToSRAM}), .CE(1'b0), .UB(1'b0), .LB(1'b0), .OE(SRAM_RE), .WE(SRAM_WE));

endmodule