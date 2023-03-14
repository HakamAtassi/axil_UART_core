`timescale 1ns/100ps

`include "../rtl/UART/UART.sv"
`include "../rtl/UART/UART_bridge.sv"
`include "../rtl/AXI_UART.sv"

module axi_tb;


initial $display("Running axi_tb.sv");


/*	UART PARAMETERS	*/
parameter C_FAMILY = "virtex6";
parameter C_S_AXI_ACLK_FREQ_HZ = 50_000_000;

parameter C_S_AXI_ADDR_WIDTH = 4;
parameter C_S_AXI_DATA_WIDTH = 32;
parameter C_S_AXI_PROTOCOL = "AXI4LITE";

parameter C_BAUDRATE = 115_200;
parameter C_DATA_BITS = 8;
parameter C_USE_PARITY = 0;
parameter C_ODD_PARITY = 0;


/*	UART I/O	*/
logic S_AXI_ACLK;								//P1	-	Clock
logic S_AXI_ARESETN;							//P2	-	Reset (active low)
wire Interrupt;									//P3	-	Interrupt


logic [C_S_AXI_ADDR_WIDTH*8-1:0] S_AXI_AWADDR;	//P4	-	Write Address
logic S_AXI_AWVALID;							//P5	-	Write Valid
wire S_AXI_AWREADY;								//P6	-	Write Ready


logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA;		//P7	-	Write Data
logic [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTB;	//P8	-	Write Strobes
logic S_AXI_WAVLID;								//P9	-	Write Valid
wire S_AXI_WREADY;								//P10	-	Write Ready


wire [1:0] S_AXI_BRESP;							//P11	-	Write Response (Faults/errors)
wire S_AXI_BVALID;								//P12	-	Write Response Valid
logic S_AXI_BREADY;								//P13	-	Write Response Ready


logic [C_S_AXI_ADDR_WIDTH*8-1:0] S_AXI_ARADDR;	//P14	-	Read Address
logic S_AXI_ARVALID;							//P15	-	Read Address Valid
wire S_AXI_ARREADY;								//P16	-	Read Address Ready



wire [C_S_AXI_ADDR_WIDTH*8-1:0] S_AXI_RDATA;	//P17	-	Read Data 
wire [1:0] S_AXI_RRESP;							//P18	-	Read Response (Faults/errors)
wire S_AXI_RVALID;								//P19	-	Read Valid
logic S_AXI_RREADY;								//P20	-	Read Ready

logic RX;										//P21	-	Recieve 
wire TX;										//P22	-	Transmit


logic Enable_rx;
logic Enable_tx;

//FPGA signals
logic Clk_50M;


logic [7:0] RX_data;
logic [7:0] TX_data;

logic rd_uart_en;
logic wr_uart_en;


parameter BAUD_IN_CLOCKS_50M = (50_000_000/C_BAUDRATE);

// ==================== DUT INST. ====================//




AXI_UART
#(
	.C_FAMILY("virtex6"),
	.C_S_AXI_ACLK_FREQ_HZ(50_000_000),
	
	.C_S_AXI_ADDR_WIDTH(4),
	.C_S_AXI_DATA_WIDTH(32),
	.C_S_AXI_PROTOCOL("AXI4LITE"),

	.C_BAUDRATE(115_200),
	.C_DATA_BITS(8),
	.C_USE_PARITY(0),
	.C_ODD_PARITY(0),

	//Embedded memory parameters
	.MEMORY_ADDR_WIDTH(18),
	.MEMORY_DATA_WIDTH(16),

	// NON-XILINX parameters (Not within spec...)
	.C_S_BASE_ADDRESS(1)
)
AXI_UART
(

	// GLOBAL SIGNALS
	.S_AXI_ACLK(S_AXI_ACLK),								//P1	-	Clock
	.S_AXI_ARESETN(S_AXI_ARESETN),							//P2	-	Reset (active low)
	.Interrupt(Interrupt),								    //P3	-	Interrupt


	// WRITE ADDRESS CHANNEL
	.S_AXI_AWADDR(S_AXI_AWADDR),	                        //P4	-	Write Address
	.S_AXI_AWVALID(S_AXI_AWVALID),							//P5	-	Write Address Valid
	.S_AXI_AWREADY(S_AXI_AWREADY),							//P6	-	Write Address Ready


	// WRITE DATA CHANNEL
	.S_AXI_WDATA(S_AXI_WDATA),	                            //P7	-	Write Data
	.S_AXI_WSTB(S_AXI_WSTB),	                            //P8	-	Write Data Strobes
	.S_AXI_WAVALID(S_AXI_WAVALID),							//P9	-	Write Data Valid
	.S_AXI_WREADY(S_AXI_WREADY),							//P10	-	Write Data Ready

	
	// WRITE RESPONSE CHANNEL
	.S_AXI_BRESP(S_AXI_BRESP),						        //P11	-	Write Response (Faults/errors)
	.S_AXI_BVALID(S_AXI_BVALID),							//P12	-	Write Response Valid
	.S_AXI_BREADY(S_AXI_BREADY),							//P13	-	Write Response Ready


	// READ ADDRESS CHANNEL
	.S_AXI_ARADDR(S_AXI_ARADDR),	                        //P14	-	Read Address
	.S_AXI_ARVALID(S_AXI_ARVALID),							//P15	-	Read Address Valid
	.S_AXI_ARREADY(S_AXI_ARREADY),							//P16	-	Read Address Ready


	// READ DATA CHANNEL
	.S_AXI_RDATA(S_AXI_RDATA),	                            //P17	-	Read Data 
	.S_AXI_RRESP(S_AXI_RRESP),						        //P18	-	Read Response (Faults/errors)
	.S_AXI_RVALID(S_AXI_RVALID),							//P19	-	Read Valid
	.S_AXI_RREADY(S_AXI_RREADY),							//P20	-	Read Ready (master ready to accept data) / TODO: use for back pressure


	.RX(RX),										//P21 	-	input to UART from HOST
	.TX(TX)										//P22	-	Transmit 
);


// ==================== TASKS ========================//

// Transmit an 8 bit word to the UART  (test RX pin)
task transmit_word_to_uart(logic [7:0] rx_data);
	RX<=1'b0;
	Enable_rx<=1'b1;

	repeat(BAUD_IN_CLOCKS_50M) @(posedge S_AXI_ACLK);
	for(int i=0;i<8;i=i+1) begin
		RX<=rx_data[0];
		rx_data<=rx_data>>1;
		repeat(BAUD_IN_CLOCKS_50M) @(posedge S_AXI_ACLK);
	end
	RX<=1'b1;
	repeat(BAUD_IN_CLOCKS_50M) @(posedge S_AXI_ACLK);
endtask

//pass word to uart and output serially to TX pin
task recieve_word_from_uart(logic [7:0] tx_data);
	Enable_tx<=1'b1;
	wr_uart_en<=1'b1;
	TX_data<=tx_data;
	@(posedge S_AXI_ACLK);
	wr_uart_en<=1'b0;
	repeat(100) @(posedge S_AXI_ACLK);
endtask

//Empty UART rx buffer (print to console)
/*
task read_word_uart;
	if(!Empty) begin
		rd_uart_en<=1'b1;
		$display("Read UART Data: %0d", RX_data);
		repeat(BAUD_IN_CLOCKS_50M) @(posedge S_AXI_ACLK);	//TODO: is this right? should it not wait 1 clk?

		rd_uart_en<=1'b0;
	end
	//repeat(1) @(posedge S_AXI_ACLK);
endtask
*/


//assign S_AXI_ARVALID=0;
task read_word_from_AXI_UART;
	S_AXI_ARVALID<=1'b1;	//set valid
	S_AXI_ARADDR<={14'd1,{18{1'b0}}};	
	@(posedge S_AXI_ACLK);
	S_AXI_ARVALID<=1'b0;
endtask


//================TEST MEM INIT. ===================//

logic [7:0] testMem [512];
initial begin
	for(int i=0;i<512;i=i+1) begin
		testMem[i]=i;
	end
end

//==============================SIGNAL DRIVING==============================//

initial begin
	$dumpfile("axi_tb");
	$dumpvars();
end

always begin
	S_AXI_ACLK<=0; #10; S_AXI_ACLK<=1; #10;
end

initial begin
	RX<=1'b1;
	Enable_rx<=1'b0;
	S_AXI_ARADDR<=0;
	S_AXI_ARESETN<=1'b1;
	S_AXI_ARESETN<=1'b0;
	@(posedge S_AXI_ACLK);
	S_AXI_ARESETN<=1'b1;
end

initial begin
	@(posedge S_AXI_ACLK);
	@(posedge S_AXI_ACLK);
	for(int i=0;i<128;i=i+1) begin
	    transmit_word_to_uart(i+1);
	end
end

logic debug_doing_read;

initial begin // Continually read when not empty
	debug_doing_read<=1'b0;
	@(posedge S_AXI_ACLK);
	repeat(100_000) @(posedge S_AXI_ACLK);
	debug_doing_read<=1'b1;
	$display("Read at %0t", $time);
	read_word_from_AXI_UART;
	@(posedge S_AXI_ACLK);
	debug_doing_read<=1'b0;
end


initial begin
	repeat(1_000_000) @(posedge S_AXI_ACLK);
	$display("Testbench duration exhausted (10_000_000 clocks)");
	$finish;
end

endmodule
