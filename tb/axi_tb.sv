`timescale 1ns/100ps

`include "../rtl/UART/UART.sv"
`include "../rtl/UART/UART_bridge.sv"





module axi_tb;

initial $display("Running axi_tb.sv");


/*	UART PARAMETERS	*/
parameter C_FAMILY = "virtex6";
parameter C_S_AXI_ACLK_FREQ_HZ = 100_000_000;

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


//FPGA signals
logic Clk_50M;



logic [7:0] RX_data;
logic [7:0] TX_data;

logic rd_uart_en;


// Transmit an 8 bit word to the UART  
task transmit_word_uart(logic [7:0] rx_data);
	RX<=1'b0;
	Enable_rx<=1'b1;

	repeat(4340) @(posedge S_AXI_ACLK);
	for(int i=0;i<8;i=i+1) begin
		RX<=rx_data[0];
		rx_data<=rx_data>>1;
		repeat(4340) @(posedge S_AXI_ACLK);
	end
	RX<=1'b1;
	repeat(4340) @(posedge S_AXI_ACLK);
endtask

//Empty UART rx buffer (print to console)
task read_word_uart;
	if(!Empty) begin
		rd_uart_en<=1'b1;
		$display("Read UART Data: %0d", RX_data);
		repeat(4340) @(posedge S_AXI_ACLK);	//TODO: is this right? should it not wait 1 clk?

		rd_uart_en<=1'b0;
	end
	//repeat(1) @(posedge S_AXI_ACLK);

endtask

logic Enable_rx;



UART
#(
    .C_BAUDRATE(115_200),
    .C_SYSTEM_FREQ(50_000_000)
)
UART(
    .Clk(Clk_50M),                   	// P0 
    .Resetn(S_AXI_ARESETN),             // P1

     // RX signals
    .RX(RX),                    		// P2   -   RX pin
    .rd_uart_en(rd_uart_en),            // P3   -   Signal a read from UART
    .Enable_rx(Enable_rx),


    .RX_data(RX_data),        			// P4   -   UART read data from RX
    .Empty(Empty),                		// P5   -   UART read fifo empty

    // TX signals
   	.TX_data(TX_data),         			// P6   -   UART write data to TX
    .wr_uart_en(wr_uart_en),            // P7   -   UART write enable

    .Full(Full),                 		// P8   -   UART write fifo full
    .TX(TX)                   			// P9   -   TX pin

);



logic [7:0] testMem [512];

initial begin
	for(int i=0;i<512;i=i+1) begin
		testMem[i]=i;
	end
end



//======================================================================//

initial begin
	$dumpfile("axi_tb");
	$dumpvars();
end

always begin
	S_AXI_ACLK<=0; #1; S_AXI_ACLK<=1; #1;
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

	for(int i=0;i<512;i=i+1) begin
		transmit_word_uart(testMem[i]);
	end

/*
	transmit_word_uart({8'b01010101});
	transmit_word_uart({8'b01010101});
	transmit_word_uart({8'b01010101});
	transmit_word_uart({8'b01010101});
	transmit_word_uart({8'd1});
	transmit_word_uart({8'd2});
	transmit_word_uart({8'd3});
	transmit_word_uart({8'd4});
	transmit_word_uart({8'd5});
	transmit_word_uart({8'd6});
	transmit_word_uart({8'd7});
*/

end

always begin 
	@(posedge S_AXI_ACLK);
	@(posedge S_AXI_ACLK);
	read_word_uart;
	@(posedge S_AXI_ACLK);
end


initial begin
	repeat(100000000) @(posedge S_AXI_ACLK);
	$display("Testbench duration exhausted (10,000,000 clocks) ");
	$finish;
end

endmodule
