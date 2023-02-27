
`include "../rtl/axi_slave.sv"
`include "../rtl/axi_master.sv"

`include "../rtl/AXI_UART.sv"

`include "../rtl/UART/UART_SRAM_interface.sv"
`include "../rtl/UART/UART_receive_controller.sv"

`include "../rtl/UART/define_state.h"



module axi_tb;

initial $display("Running axi_tb.sv");


/*	UART PARAMETERS	*/
parameter C_FAMILY = "virtex6";
parameter C_S_AXI_ACLK_FREQ_HZ = 100_000_000;

parameter C_S_AXI_ADDR_WIDTH = 4;
parameter C_S_AXI_DATA_WIDTH = 32;
parameter C_S_AXI_PROTOCOL = "AXI4LITE";

parameter C_BAUDRATE = 9600;
parameter C_DATA_BITS = 8;
parameter C_USE_PARITY = 0;
parameter C_ODD_PARITY = 0;


/*	UART I/O	*/
logic S_AXI_ACLK;								//P1	-	Clock
logic S_AXI_ARESETN;							//P2	-	Reset (active low)
wire Interrupt;								//P3	-	Interrupt


logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR;	//P4	-	Write Address
logic S_AXI_AWVALID;							//P5	-	Write Valid
wire S_AXI_AWREADY;							//P6	-	Write Ready


logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA;		//P7	-	Write Data
logic [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTB;	//P8	-	Write Strobes
logic S_AXI_WAVLID;								//P9	-	Write Valid
wire S_AXI_WREADY;								//P10	-	Write Ready


wire [1:0] S_AXI_BRESP;						//P11	-	Write Response (Faults/errors)
wire S_AXI_BVALID;								//P12	-	Write Response Valid
logic S_AXI_BREADY;								//P13	-	Write Response Ready


logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR;	//P14	-	Read Address
logic S_AXI_ARVALID;							//P15	-	Read Address Valid
wire S_AXI_ARREADY;							//P16	-	Read Address Ready



wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_RDATA;		//P17	-	Read Data 
wire [1:0] S_AXI_RRESP;						//P18	-	Read Response (Faults/errors)
wire S_AXI_RVALID;								//P19	-	Read Valid
logic S_AXI_RREADY;								//P20	-	Read Ready

logic RX;										//P21	-	Recieve 
wire TX;										//P22	-	Transmit

//======================================================================//


always begin
	S_AXI_ACLK<=0; #5; S_AXI_ACLK<=1;
end







initial begin


end





initial begin
	repeat(10000) @(posedge S_AXI_ACLK);
	$display("Testbench duration exhausted (10,000 clocks) ");
	$finish;
end

endmodule
