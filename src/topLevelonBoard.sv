module topLevelOnBoard( 
					  input logic Clk, 
					  input logic Reset, 
					  input logic Run,
					  output logic mstrReady,
					  output logic [19:0] ADDR,
					  inout wire [15:0] Data,
					  output logic OE,
					  output logic WE,
					  output logic CE,
					  output logic UB,
					  output logic LB,
					  output logic [6:0] State
					  );

	wire MSTR_WE;
	wire MSTR_OE;
	wire [15:0] ADDR0;
	wire [15:0] DATA0;
	wire [15:0] ADDR1;
	wire [15:0] DATA1;
	wire [15:0] ADDR2;
	wire [15:0] DATA2;
	wire [15:0] ADDR3;
	wire [15:0] DATA3;
	wire [15:0] ADDR4;
	wire [15:0] DATA4;
	wire [15:0] fromTristate;
	wire [15:0] toTristate;
	wire [15:0] addressToSRAM;
	wire [15:0] DataToCPUs;
	wire SRAM_WE;
	wire SRAM_RE;
	wire ReqDone_4, ReqDone_3, ReqDone_2, ReqDone_1, ReqDone_0; // request done signals
	wire [15:0] from_PC_1;
	wire [15:0] from_PC_2;
	wire [15:0] from_PC_3;
	wire [15:0] from_PC_4;
	wire [3:0] CPU_SEL;
	wire [15:0] SRAM_IO;
	wire SLV1_WE;
	wire SLV1_OE;
	wire SLV2_WE;
	wire SLV2_OE;
	wire SLV3_WE;
	wire SLV3_OE;
	wire SLV4_WE;
	wire SLV4_OE;
	wire Ready0;
	wire Ready1;
	wire Ready2;
	wire Ready3;
	wire Ready4;
	wire SRAM_CE;
	
	assign mstrReady = Ready0;
	assign ADDR = {4'b0000, addressToSRAM};
	assign OE = SRAM_RE;
	assign WE = SRAM_WE;
	assign CE = SRAM_CE;
	assign UB = 1'b0;
	assign LB = 1'b0;
	

IOhandler2 o_IOhandler( .clk(Clk),
							  .reset(Reset),
							  .run(Run),
							  .writeRequest({~SLV4_WE, ~SLV3_WE, ~SLV2_WE, ~SLV1_WE, ~MSTR_WE}),
							  .readRequest({~SLV4_OE, ~SLV3_OE, ~SLV2_OE, ~SLV1_OE, ~MSTR_OE}),
							  .ADDR0(ADDR0),
							  .DATA0(DATA0),
							  .ADDR1(ADDR1),
							  .DATA1(DATA1),
							  .ADDR2(ADDR2),
							  .DATA2(DATA2),
							  .ADDR3(ADDR3),
							  .DATA3(DATA3),
							  .ADDR4(ADDR4),
							  .DATA4(DATA4),
							  .fromTristate(fromTristate),
							  .toTristate(toTristate),
							  .addressToSRAM(addressToSRAM),
							  .DataToCPUs(DataToCPUs),
							  .SRAM_WE(SRAM_WE),
							  .SRAM_RE(SRAM_RE),
							  .SRAM_CE(SRAM_CE),
							  .requestDone({ReqDone_4, ReqDone_3, ReqDone_2, ReqDone_1, ReqDone_0}) );

tristate o_tristate ( .Clk(Clk),
							 .tristate_output_enable(~SRAM_WE),
							 .Data_write(toTristate),
							 .Data_read(fromTristate),
							 .Data(Data));
							 
slc3 master(.S(16'b0),
			.Clk(Clk),
			.Reset(Reset),
			.Run(Run),
			.Continue(1'b0),
			.from_PC_X(16'b0),
			.Ready1,
			.Ready2,
			.Ready3,
			.Ready4,
			.fromCPU_SEL(1'b0),
			.CPU_ID(3'b0),
			.memReady(ReqDone_0),
			.Data_from_SRAM(DataToCPUs),
			.CPU_READY(Ready0),
			.from_PC_1(from_PC_1),
			.from_PC_2(from_PC_2),
			.from_PC_3(from_PC_3),
			.from_PC_4(from_PC_4),
			.CPU_SEL(CPU_SEL),
			.OE(MSTR_OE),
			.WE(MSTR_WE),
			.ADDR(ADDR0),
			.Data_to_SRAM(DATA0)
			//.State(State[5:0])
			);
			
assign State[6] = 1'b0;
			
slc3 slave1(.S(16'b0),
			.Clk(Clk),
			.Reset(Reset),
			.Run(Run),
			.Continue(1'b0),
			.from_PC_X(from_PC_1),
			.fromCPU_SEL(CPU_SEL[3]),
			.CPU_ID(3'b001),
			.memReady(ReqDone_1),
			.Data_from_SRAM(DataToCPUs),
			.CPU_READY(Ready1),
			.OE(SLV1_OE),
			.WE(SLV1_WE),
			.ADDR(ADDR1),
			.Data_to_SRAM(DATA1),
			.State(State[5:0])
			);
slc3 slave2(.S(16'b0),
			.Clk(Clk),
			.Reset(Reset),
			.Run(Run),
			.Continue(1'b0),
			.from_PC_X(from_PC_2),
			.fromCPU_SEL(CPU_SEL[2]),
			.CPU_ID(3'b010),
			.memReady(ReqDone_2),
			.Data_from_SRAM(DataToCPUs),
			.CPU_READY(Ready2),
			.OE(SLV2_OE),
			.WE(SLV2_WE),
			.ADDR(ADDR2),
			.Data_to_SRAM(DATA2)
			);
slc3 slave3(.S(16'b0),
			.Clk(Clk),
			.Reset(Reset),
			.Run(Run),
			.Continue(1'b0),
			.from_PC_X(from_PC_3),
			.fromCPU_SEL(CPU_SEL[1]),
			.CPU_ID(3'b011),
			.memReady(ReqDone_3),
			.Data_from_SRAM(DataToCPUs),
			.CPU_READY(Ready3),
			.OE(SLV3_OE),
			.WE(SLV3_WE),
			.ADDR(ADDR3),
			.Data_to_SRAM(DATA3)
			);
slc3 slave4(.S(16'b0),
			.Clk(Clk),
			.Reset(Reset),
			.Run(Run),
			.Continue(1'b0),
			.from_PC_X(from_PC_3),
			.fromCPU_SEL(CPU_SEL[0]),
			.CPU_ID(3'b100),
			.memReady(ReqDone_4),
			.Data_from_SRAM(DataToCPUs),
			.CPU_READY(Ready4),
			.OE(SLV4_OE),
			.WE(SLV4_WE),
			.ADDR(ADDR4),
			.Data_to_SRAM(DATA4)
			);


endmodule