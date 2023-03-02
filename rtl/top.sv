// Top level integration for the AXI4-lite ram and UART module

module top
#(
	parameter C_FAMILY = "virtex6",
	parameter C_M_AXI_ACLK_FREQ_HZ = 100000000,
	
	parameter C_M_AXI_ADDR_WIDTH = 4,
	parameter C_M_AXI_DATA_WIDTH = 32,
	parameter C_M_AXI_PROTOCOL = "AXI4LITE",

	parameter C_BAUDRATE = 9600,
	parameter C_DATA_BITS = 8,
	parameter C_USE_PARITY = 0,
	parameter C_ODD_PARITY = 0,

	//Embedded memory parameters
	parameter MEMORY_ADDR_WIDTH = 18,
	parameter MEMORY_DATA_WIDTH = 16

)
(

	input clk,
	input resetn,

	input logic RX,
	input logic UART_initialize



);



// =========================== MASTER SIGNALS =========================//
// =========================== AXI_UART outputs =========================//



// GLOBAL SIGNALS
logic Interrupt;								//P3	-	Interrupt


// WRITE ADDRESS CHANNEL
logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR;	//P4	-	Write Address
logic M_AXI_AWVALID;							//P5	-	Write Valid


// WRITE DATA CHANNEL
logic [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA;		//P7	-	Write Data
logic [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTB;	//P8	-	Write Strobes
logic M_AXI_WAVLID;								//P9	-	Write Valid


// WRITE RESPONSE CHANNEL
logic M_AXI_BREADY;								//P13	-	Write Response Ready


// READ ADDRESS CHANNEL
logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR;	//P14	-	Read Address
logic M_AXI_ARVALID;							//P15	-	Read Address Valid


// READ DATA CHANNEL
logic M_AXI_RREADY;								//P20	-	Read Ready


logic TX;										//P22	-	Transmit (not used)
logic UART_enable;								//TODO Output?


// =========================== SLAVE SIGNALS =========================//
// ========================== axil_ram outputs ========================//


// WRITE ADDRESS CHANNEL
wire [C_M_AXI_ADDR_WIDTH-1:0] s_axil_awaddr;
wire s_axil_wready;

wire [1:0] s_axil_bresp;						

wire [2:0] s_axil_awprot;

wire s_axil_awvalid;

wire s_axil_bvalid;		

wire s_axil_arready;

wire [C_M_AXI_DATA_WIDTH-1:0] s_axil_rdata;
wire [1:0] s_axil_rresp;
wire s_axil_rvalid;



AXI_UART#(
	.C_FAMILY("virtex6"),
	.C_M_AXI_ACLK_FREQ_HZ(C_M_AXI_ACLK_FREQ_HZ),
	
	.C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
	.C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
	.C_M_AXI_PROTOCOL(C_M_AXI_PROTOCOL),

	.C_BAUDRATE(C_BAUDRATE),
	.C_DATA_BITS(C_DATA_BITS),
	.C_USE_PARITY(C_USE_PARITY),
	.C_ODD_PARITY(C_ODD_PARITY),

	.MEMORY_ADDR_WIDTH(MEMORY_ADDR_WIDTH),
	.MEMORY_DATA_WIDTH(MEMORY_DATA_WIDTH)
)
AXI_UART (
	.M_AXI_ACLK(clk),								//P1	-	Clock
	.M_AXI_ARESETN(resetn),							//P2	-	Reset (active low)
	.Interrupt(Interrupt),							//P3	-	Interrupt


	.M_AXI_AWADDR(M_AXI_AWADDR),					//P4	-	Write Address
	.M_AXI_AWVALID(M_AXI_AWVALID),					//P5	-	Write Valid
	.M_AXI_AWREADY(s_axil_awready),					//P6	-	Write Ready


	.M_AXI_WDATA(M_AXI_WDATA),						//P7	-	Write Data
	.M_AXI_WSTB(M_AXI_WSTB),						//P8	-	Write Strobes
	.M_AXI_WAVALID(M_AXI_WAVALID),					//P9	-	Write Valid
	.M_AXI_WREADY(s_axil_wready),					//P10	-	Write Ready


	.M_AXI_BRESP(s_axil_bresp),						//P11	-	Write Response (Faults/errors)
	.M_AXI_BVALID(s_axil_bvalid),					//P12	-	Write Response Valid
	.M_AXI_BREADY(M_AXI_BREADY),					//P13	-	Write Response Ready


	.M_AXI_ARADDR(M_AXI_ARADDR),					//P14	-	Read Address
	.M_AXI_ARVALID(M_AXI_ARVALID),					//P15	-	Read Address Valid
	.M_AXI_ARREADY(s_axil_arready),					//P16	-	Read Address Ready


	.M_AXI_RDATA(s_axil_rdata),						//P17	-	Read Data 
	.M_AXI_RRESP(s_axil_rresp),						//P18	-	Read Response (Faults/errors)
	.M_AXI_RVALID(s_axil_rvalid),					//P19	-	Read Valid
	.M_AXI_RREADY(M_AXI_RREADY),					//P20	-	Read Ready

	.UART_RX_I(RX),									//P21	-	Recieve 
	.TX(TX),											//P22	-	Transmit


	.UART_initialize(UART_initialize),
	.UART_enable(UART_enable)

);

axil_ram #(
    // Width of data bus in bits
    .DATA_WIDTH(C_M_AXI_DATA_WIDTH),
    // Width of address bus in bits
    .ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
    // Width of wstrb (width of data bus in words)
    .STRB_WIDTH(C_M_AXI_DATA_WIDTH/8),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
)
axil_ram
(
	// GLOBAL SIGNALS
    .clk(clk),
    .rst(resetn),

	// WRITE ADDRESS CHANNEL
    .s_axil_awaddr(M_AXI_AWADDR),
    .s_axil_awprot(s_axil_awprot),	//Not used by UART
    .s_axil_awvalid(M_AXI_AWVALID),
    .s_axil_awready(s_axil_awready),

	// WRITE DATA CHANNEL
    .s_axil_wdata(M_AXI_WDATA),
    .s_axil_wstrb(M_AXI_WSTB),
    .s_axil_wvalid(M_AXI_WAVALID),
    .s_axil_wready(s_axil_wready),


	// WRITE RESPONSE CHANNEL
    .s_axil_bresp(s_axil_bresp),
	.s_axil_bvalid(s_axil_bv),
    .s_axil_bready(M_AXI_BREADY),


	// READ ADDRESS CHANNEL
    .s_axil_araddr(M_AXI_ARADDR),
    .s_axil_arprot(M_AXI_ARPROT),	//Not used by UART
    .s_axil_arvalid(M_AXI_ARVALID),
    .s_axil_arready(s_axil_arready),


	// READ DATA CHANNEL
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(M_AXI_RREADY)
);





endmodule

