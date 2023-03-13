`timescale 1ns/100ps

`include "../rtl/UART/UART.sv"
`include "../rtl/UART/UART_bridge.sv"

module axi_tb;


initial $display("Running UART_tb.sv");


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


logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR;	//P4	-	Write Address
logic S_AXI_AWVALID;							//P5	-	Write Valid
wire S_AXI_AWREADY;								//P6	-	Write Ready


logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA;		//P7	-	Write Data
logic [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTB;	//P8	-	Write Strobes
logic S_AXI_WAVLID;								//P9	-	Write Valid
wire S_AXI_WREADY;								//P10	-	Write Ready


wire [1:0] S_AXI_BRESP;							//P11	-	Write Response (Faults/errors)
wire S_AXI_BVALID;								//P12	-	Write Response Valid
logic S_AXI_BREADY;								//P13	-	Write Response Ready


logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR;	//P14	-	Read Address
logic S_AXI_ARVALID;							//P15	-	Read Address Valid
wire S_AXI_ARREADY;								//P16	-	Read Address Ready



wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_RDATA;		//P17	-	Read Data 
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
task read_word_uart;
	if(!Empty) begin
		rd_uart_en<=1'b1;
		$display("Read UART Data: %0d", RX_data);
		repeat(BAUD_IN_CLOCKS_50M) @(posedge S_AXI_ACLK);	//TODO: is this right? should it not wait 1 clk?

		rd_uart_en<=1'b0;
	end
	//repeat(1) @(posedge S_AXI_ACLK);

endtask



UART
#(
    .C_BAUDRATE(C_BAUDRATE),
    .C_SYSTEM_FREQ(50_000_000)
)
UART(
    .Clk(Clk_50M),
    .Resetn(S_AXI_ARESETN),

     // RX signals
    .RX(RX),
    .rd_uart_en(rd_uart_en),
    .Enable_rx(Enable_rx),


    .RX_data(RX_data),
    .Empty(Empty),                	

    // TX signals
   	.TX_data(TX_data),
    .wr_uart_en(wr_uart_en),          
    .Enable_tx(Enable_tx),      	

    .Full(Full),
    .TX(TX)

);



logic [7:0] testMem [512];

initial begin
	for(int i=0;i<512;i=i+1) begin
		testMem[i]=i;
	end
end



//======================================================================//

initial begin
	$dumpfile("UART_tb");
	$dumpvars();
end

always begin
	S_AXI_ACLK<=0; #10; S_AXI_ACLK<=1; #10;
end

always begin
	Clk_50M<=0;	#10; Clk_50M<=1; #10;
end

initial begin
	RX<=1'b1;
	Enable_rx<=1'b0;
	S_AXI_ARESETN<=1'b1;
	S_AXI_ARESETN<=1'b0;
	@(posedge S_AXI_ACLK);
	S_AXI_ARESETN<=1'b1;
end

initial begin
	@(posedge S_AXI_ACLK);
	@(posedge S_AXI_ACLK);
	for(int i=0;i<128;i=i+1) begin
		transmit_word_to_uart(testMem[i]);
	end
end

always begin 
	@(posedge S_AXI_ACLK);
	@(posedge S_AXI_ACLK);
	read_word_uart;
	@(posedge S_AXI_ACLK);
end


// test TX module
initial begin
	@(posedge S_AXI_ACLK);
	@(posedge S_AXI_ACLK);
	for(int i=0;i<128;i=i+1) begin
		recieve_word_from_uart(i);	
	end
end



initial begin
	repeat(10000000) @(posedge S_AXI_ACLK);
	$display("Testbench duration exhausted (10,000,000 clocks) ");
	$finish;
end

endmodule
