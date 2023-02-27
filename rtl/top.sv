// Top level integration for the AXI4-lite ram and UART module

module top
(

	input clk,
	input resetn,

	input logic RX,
	input logic UART_initialize



);

// =========================== MASTER SIGNALS =========================//


// GLOBAL SIGNALS
logic Interrupt,								//P3	-	Interrupt


// WRITE ADDRESS CHANNEL
logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,	//P4	-	Write Address
logic M_AXI_AWVALID,							//P5	-	Write Valid


// WRITE DATA CHANNEL
logic [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,		//P7	-	Write Data
logic [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTB,	//P8	-	Write Strobes
logic M_AXI_WAVLID,								//P9	-	Write Valid


// WRITE RESPONSE CHANNEL
logic [1:0] M_AXI_BRESP,						//P11	-	Write Response (Faults/errors)
logic M_AXI_BVALID,								//P12	-	Write Response Valid

// READ ADDRESS CHANNEL
logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,	//P14	-	Read Address
logic M_AXI_ARVALID,							//P15	-	Read Address Valid


// READ DATA CHANNEL
logic M_AXI_RREADY,								//P20	-	Read Ready


// =========================== SLAVE SIGNALS =========================//


// WRITE ADDRESS CHANNEL
wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
wire [2:0]             s_axil_awprot,	//Not used by UART
wire                   s_axil_awvalid,

// WRITE DATA CHANNEL
wire [DATA_WIDTH-1:0]  s_axil_wdata,
wire [STRB_WIDTH-1:0]  s_axil_wstrb,
wire                   s_axil_wvalid,


// WRITE RESPONSE CHANNEL
wire                   s_axil_bready,


// READ ADDRESS CHANNEL
wire [ADDR_WIDTH-1:0]  s_axil_araddr,
wire [2:0]             s_axil_arprot,	//Not used by UART
wire                   s_axil_arvalid,


// READ DATA CHANNEL
wire                   s_axil_rready



AXI_UART#(
	.C_FAMILY("virtex6"),
	.C_S_AXI_ACLK_FREQ_HZ(100000000),
	
	.C_S_AXI_ADDR_WIDTH(4),
	.C_S_AXI_DATA_WIDTH(32),
	.C_S_AXI_PROTOCOL("AXI4LITE"),

	.C_BAUDRATE(9600),
	.C_DATA_BITS(8),
	.C_USE_PARITY(0),
	.C_ODD_PARITY(0)
)
AXI_UART (
	.S_AXI_ACLK(clk),								//P1	-	Clock
	.S_AXI_ARESETN(resetn),							//P2	-	Reset (active low)
	.Interrupt(Interrupt),							//P3	-	Interrupt


	.S_AXI_AWADDR(S_AXI_AWADDR),					//P4	-	Write Address
	.S_AXI_AWVALID(S_AXI_AWVALID),					//P5	-	Write Valid
	.S_AXI_AWREADY(s_axil_awready),					//P6	-	Write Ready


	.S_AXI_WDATA(S_AXI_WDATA),						//P7	-	Write Data
	.S_AXI_WSTB(S_AXI_WSTB),						//P8	-	Write Strobes
	.S_AXI_WAVLID(S_AXI_WAVLID),					//P9	-	Write Valid
	.S_AXI_WREADY(s_axil_wready),					//P10	-	Write Ready


	.S_AXI_BRESP(s_axil_bresp),						//P11	-	Write Response (Faults/errors)
	.S_AXI_BVALID(s_axil_bvalid),					//P12	-	Write Response Valid
	.S_AXI_BREADY(S_AXI_BREADY),					//P13	-	Write Response Ready


	.S_AXI_ARADDR(S_AXI_ARADDR),					//P14	-	Read Address
	.S_AXI_ARVALID(S_AXI_ARVALID),					//P15	-	Read Address Valid
	.S_AXI_ARREADY(s_axil_arready),					//P16	-	Read Address Ready


	.S_AXI_RDATA(s_axil_rdata),						//P17	-	Read Data 
	.S_AXI_RRESP(s_axil_rresp),						//P18	-	Read Response (Faults/errors)
	.S_AXI_RVALID(s_axil_rvalid),					//P19	-	Read Valid
	.S_AXI_RREADY(S_AXI_RREADY),					//P20	-	Read Ready

	.RX(RX),										//P21	-	Recieve 
	.TX(TX)											//P22	-	Transmit
);


axil_ram axil_ram #(
    // Width of data bus in bits
    .DATA_WIDTH(16),
    // Width of address bus in bits
    .ADDR_WIDTH(18),
    // Width of wstrb (width of data bus in words)
    .STRB_WIDTH(DATA_WIDTH/8),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
)
(
	// GLOBAL SIGNALS
    .clk(clk),
    .rst(resetn),

	// WRITE ADDRESS CHANNEL
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),	//Not used by UART
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(S_AXI_AWREADY),

	// WRITE DATA CHANNEL
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(S_AXI_WREADY),


	// WRITE RESPONSE CHANNEL
    .s_axil_bresp(S_AXI_BRESP),
    
	.s_axil_bvalid(S_AXI_BVALID),
    .s_axil_bready(s_axil_bready),


	// READ ADDRESS CHANNEL
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),	//Not used by UART
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(S_AXI_ARREADY),


	// READ DATA CHANNEL
    .s_axil_rdata(S_AXI_RDATA),
    .s_axil_rresp(S_AXI_RRESP),
    .s_axil_rvalid(S_AXI_RVALID),
    .s_axil_rready(s_axil_rready)
);






endmodule

