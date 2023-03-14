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



//TODO: update this on how it actually works because I changed things a bit
// Brief note on memory mapping:
// Since for the time being, the system will likely only consist of a few slave UART cores and a few arbitrary 
// Master cores (no main memory), the memory map will not be very sophisticated. 

// Currently, each instantiated UART core will accept a single value for its address
// ie: UART 0's address is 0, UART 1's address is 1. These values will be placed on the first available IO address space bits (MEMORY_ADDR_WIDTH+)
//
// System address width is assumed to be 32 bits wide. 

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
	parameter MEMORY_DATA_WIDTH = 16,

	// NON-XILINX parameters (Not within spec...)
	parameter C_S_BASE_ADDRESS = 0

)
(

	// GLOBAL SIGNALS
	input logic S_AXI_ACLK,								//P1	-	Clock
	input logic S_AXI_ARESETN,							//P2	-	Reset (active low)
	output logic Interrupt,								//P3	-	Interrupt


	// WRITE ADDRESS CHANNEL
	input logic [C_S_AXI_ADDR_WIDTH*8-1:0] S_AXI_AWADDR,//P4	-	Write Address
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
	input logic [C_S_AXI_ADDR_WIDTH*8-1:0] S_AXI_ARADDR,//P14	-	Read Address
	input logic S_AXI_ARVALID,							//P15	-	Read Address Valid
	output logic S_AXI_ARREADY,							//P16	-	Read Address Ready


	// READ DATA CHANNEL
	output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,	//P17	-	Read Data 
	output logic [1:0] S_AXI_RRESP,						//P18	-	Read Response (Faults/errors)
	output logic S_AXI_RVALID,							//P19	-	Read Valid
	input logic S_AXI_RREADY,							//P20	-	Read Ready (master ready to accept data) / TODO: use for back pressure


	input logic RX,										//P21 	-	input to UART from HOST
	output logic TX										//P22	-	Transmit 
);


// Parameter defs.

parameter ADDRESS_WIDTH = C_S_AXI_ADDR_WIDTH*8;
parameter MMIO_ADDRESS_WIDTH = ADDRESS_WIDTH-MEMORY_ADDR_WIDTH;

// Wire renaming

wire [0:MMIO_ADDRESS_WIDTH-1] MMIO_address_write;
wire [0:MMIO_ADDRESS_WIDTH-1] MMIO_address_read;



assign MMIO_address_write = S_AXI_AWADDR[(ADDRESS_WIDTH-1):(MEMORY_ADDR_WIDTH)];	//Extract I/O base addresses
assign MMIO_address_read = S_AXI_ARADDR[(ADDRESS_WIDTH-1):(MEMORY_ADDR_WIDTH)];


//=============== UART INST. ==============//


logic Enable_rx;
logic rd_uart_en;
logic [7:0] RX_data;
logic Empty;

logic [7:0] TX_data;
logic Enable_tx;
logic wr_uart_en;

logic Full;


UART
#(
    .C_BAUDRATE(C_BAUDRATE),
    .C_SYSTEM_FREQ(C_S_AXI_ACLK_FREQ_HZ)
)
UART(
    .Clk(S_AXI_ACLK),                  	// P0 
    .Resetn(S_AXI_ARESETN),             // P1

    // RX signals
    .RX(RX),                    		// P2   -   RX pin
    .rd_uart_en(rd_uart_en),            // P3   -   Signal a read from UART (Unload)
    .Enable_rx(Enable_rx),				// P4	-	Enable rx module


    .RX_data(RX_data),        			// P5   -   UART read data from RX
    .Empty(Empty),                		// P6   -   UART read fifo empty

    // TX signals
   	.TX_data(TX_data),         			// P7   -   UART write data to TX
    .wr_uart_en(wr_uart_en),            // P8   -   UART write enable
	.Enable_tx(Enable_tx),				// P9	-	Enable tx module

    .Full(Full),                 		// P10   -  UART write fifo full
    .TX(TX)                   			// P11   -  TX pin

);

assign Enable_rx=1'b1;	//RX and TX modules always on
assign Enable_tx=1'b1;



//Register the outputs
logic S_AXI_WREADY_reg;
logic S_AXI_RREADY_reg;

logic S_AXI_AWREADY_reg;

wire address_valid_and_in_range;

wire write_valid;


// Output assignments
assign S_AXI_AWREADY = S_AXI_AWREADY_reg;

assign S_AXI_WREADY = S_AXI_WREADY_reg;	//if TX fifo is not full, write is ready
//assign S_AXI_RREADY = S_AXI_RREADY_reg;	//if RX fifo is not empty, read is ready



//========================================================================================
//======================================AXI READ LOGIC====================================
//========================================================================================

// 1) Check if read address is valid and in range
// 2) Check if UART is ready to be read from 
//     2.1) Yes => if master is ready to accept, output a word by reading from fifo and enable READ_VALID
//     			   if master is not ready to accept (busy) wait till master is available.
//    2.2)  No =>  Output corresponding error to read response channel.




// TODO: make registers for the outputs (required)

// what are the ouputs of the UART when reading??

logic S_AXI_ARREADY_reg;	// Read address ready output must be registered

logic [0:3] read_valid_buffer;	// Buffer to delay the read response by 2 clocks (right-most bit not included)

wire read_valid_in_range;


assign read_valid_in_range = (S_AXI_ARVALID && (MMIO_address_read==C_S_BASE_ADDRESS));	//check if address for read is valid and in range

assign S_AXI_ARREADY = S_AXI_ARREADY_reg;	

assign rd_uart_en = !Empty && read_valid_in_range;	// Initiate the read

assign S_AXI_RVALID = read_valid_buffer[0];

assign S_AXI_RDATA = RX_data;


always_ff @(posedge S_AXI_ACLK, negedge S_AXI_ARESETN) begin
	if(!S_AXI_ARESETN) begin
		S_AXI_ARREADY_reg<=1'b0;
	end else begin
		S_AXI_ARREADY_reg<=!Empty;	// Address is ready to be read from if the UART RX FIFO is not empty.
	end
end


// TODO: this does not account for back pressure... (valid should not be shifted out if it wasnt accepted by master...)
//when a read has been requested from the UART, delay the valid bit a few clocks while the read request is returned
always_ff @ (posedge S_AXI_ACLK, negedge S_AXI_ARESETN) begin
	if(!S_AXI_ARESETN) begin
		read_valid_buffer<=0;
	end else begin
		read_valid_buffer<={rd_uart_en,read_valid_buffer[0:2]};
	end
end















/*



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
*/

// write ready is if tx fifo is not full
// read ready is if rx fifo is not empty
// backpressure?
// address ready?


// handel actual reads and writes





endmodule
