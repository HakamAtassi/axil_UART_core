// ================================================================================================================
//																			
//	  	  _____________________________		 ___      	 __________________________________      ________________
//		 |		AXI MASTER   		  |		|   |		|	             UART              | 	|				 |
//		 |	 _______	  __________  |		|	|		|	 ___________      __________   |	|				 |
//		 |	|		|	 |			| |		|	|		|	|			|	 |			|  |	|				 |
//		 |	|		|    |			| |		| 	|		|	|			|	 |			|  |   	|	Host System	 |
//		 |	|  CORE |<=> | M_AXI    | |<==>	|Bus| <==>	|	| S_AXI     | <= |   UART   |  | <=>|	   (PC)   	 |
//		 |	|		|	 | Interface| |  	|   |		|	| Interface |	 |	 RX/TX  |  |	|				 |
//		 |	|		|	 |			| |		|   |		|	|			|	 |          |  |	|				 |
//		 |	|_______|	 |__________| |		|   |		|	|___________|    |__________|  |	|				 |
//		 |							  |		|   |		|								   |	|				 |
//		 |____________________________|		|___|		|__________________________________|	|________________|
//
//
// ================================================================================================================



module AXI_UART
#(

	parameter C_FAMILY = "virtex6",
	parameter C_S_AXI_ACLK_FREQ_HZ = 100_000_000,
	
	parameter C_S_AXI_ADDR_WIDTH = 4,
	parameter C_S_AXI_DATA_WIDTH = 32,
	parameter C_S_AXI_PROTOCOL = "AXI4LITE",

	parameter C_BAUDRATE = 115_200,
	parameter C_DATA_BITS = 8,
	parameter C_USE_PARITY = 0,
	parameter C_ODD_PARITY = 0,

	//Embedded memory parameters
	parameter MEMORY_ADDR_WIDTH = 18,
	parameter MEMORY_DATA_WIDTH = 16

)
(

	// GLOBAL SIGNALS
	input logic S_AXI_ACLK,								//P1	-	Clock
	input logic S_AXI_ARESETN,							//P2	-	Reset (active low)
	output logic Interrupt,								//P3	-	Interrupt


	// WRITE ADDRESS CHANNEL
	input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,	//P4	-	Write Address
	input logic S_AXI_AWVALID,							//P5	-	Write Address Valid
	output logic S_AXI_AWREADY,							//P6	-	Write Address Ready


	// WRITE DATA CHANNEL
	input logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,	//P7	-	Write Data
	input logic [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTB,	//P8	-	Write Data Strobes
	input logic S_AXI_WAVALID,							//P9	-	Write Data Valid
	output logic S_AXI_WREADY,							//P10	-	Write Data Ready

	
	// WRITE RESPONSE CHANNEL
	output logic [1:0] S_AXI_BRESP,						//P11	-	Write Response (Faults/errors)
	output logic S_AXI_BVALID,							//P12	-	Write Response Valid
	input logic S_AXI_BREADY,							//P13	-	Write Response Ready


	// READ ADDRESS CHANNEL
	input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,	//P14	-	Read Address
	input logic S_AXI_ARVALID,							//P15	-	Read Address Valid
	output logic S_AXI_ARREADY,							//P16	-	Read Address Ready


	// READ DATA CHANNEL
	output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,	//P17	-	Read Data 
	output logic [1:0] S_AXI_RRESP,						//P18	-	Read Response (Faults/errors)
	output logic S_AXI_RVALID,							//P19	-	Read Valid
	input logic S_AXI_RREADY,							//P20	-	Read Ready (master ready to accept data) / TODO: use for back pressure


	input logic RX,										//P21 	-	input to UART from HOST
	output logic TX,									//P22	-	Transmit 
	

);


//=============== UART INST. ==============//


logic Enable_rx;
logic rd_uart_en;
logic RX_data;
logic Empty;

logic TX_data;
logic Enable_tx;
logic wr_uart_en;

logic Full;


UART
#(
    .C_BAUDRATE(C_BAUDRATE),
    .C_SYSTEM_FREQ(50_000_000)
)
UART(
    .Clk(S_AXI_ACLK),                  	// P0 
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
	.Enable_tx(Enable_tx),


    .Full(Full),                 		// P8   -   UART write fifo full
    .TX(TX)                   			// P9   -   TX pin

);


//Register the outputs
logic S_AXI_WREADY_reg;
logic S_AXI_RREADY_reg;

logic S_AXI_AWREADY_reg;
logic S_AXI_ARREADY_reg;


wire address_valid_and_in_range;


wire write_valid;


// Output assignments
assign S_AXI_AWREADY = S_AXI_AWREADY_reg;
assign S_AXI_ARREADY= S_AXI_ARREADY_reg;

assign S_AXI_WREADY = S_AXI_WREADY_reg;	//if TX fifo is not full, write is ready
assign S_AXI_RREADY = S_AXI_RREADY_reg;	//if RX fifo is not empty, read is ready




// is this periphiral being addressed?
//TODO: how do I check if the input address is using the correct range without a comparator?
assign address_valid_and_in_range  = S_AXI_AWVALID && (S_AXI_AWADDR && ());	//is this periphiral being addressed? (address valid and matches this periphiral)


// write occurs when write address is valid and in range && fifo is not full && data is valid
assign write_valid = address_valid_and_in_range && S_AXI_WREADY_reg && S_AXI_WREADY;


Enable_rx<=1'b1;	//RX module always reading/polling line
Enable_tx<=1'b1;	//TX always writing buffer contents to line 

always_ff @ (posedge S_AXI_ACLK, negedge S_AXI_ARESETN) begin
	
	if(!S_AXI_ARESETN) begin
		S_AXI_AWREADY_reg<=1'b0;
		S_AXI_ARREADY_reg<=1'b0;
		
		S_AXI_WREADY_reg<=1'b0;
		S_AXI_RREADY_reg<=1'b0;
	end else begin
		S_AXI_AWREADY_reg<=1'b1;	//write address and read address are always ready
		S_AXI_ARREADY_reg<=1'b1;	//they dont exist in uarts as data is just placed/read from fifo

		S_AXI_WREADY_reg<=1'b0;
		S_AXI_RREADY_reg<=1'b0;

		if(!Full) S_AXI_WREADY_reg<=1'b1;
		if(!Empty) S_AXI_RREADY_reg<=1'b1;

	end
end


//for writes to UART, if write data is valid && S_AXI_WREADY_reg, perform stove and send data to fifo
//write response stuff

always_ff @(posedge S_AXI_ACLK) begin
	Enable_tx<=1'b0;
	wr_uart_en<=1'b0;

	if(write_valid) begin	//backpressure if unable to write to fifo?
		//perform strobe and write data to fifo
		TX_data<=S_AXI_WDATA;
		wr_uart_en<=1'b1;

		// TODO: handel response...
	end

end


// write ready is if tx fifo is not full
// read ready is if rx fifo is not empty
// backpressure?
// address ready?


// handel actual reads and writes





endmodule
