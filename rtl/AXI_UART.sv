// AXI UART
// May not be entirely AXI compliant. Use with caution.
//
//
// ================================================================================================================
//																			
//	  	  _____________________________		 ___      	 __________________________________      ________________
//		 |		Embedded Mem		  |		|   |		|	             UART              | 	|				 |
//		 |	 _______	  __________  |		|	|		|	 ___________      __________   |	|				 |
//		 |	|		|	 |			| |		|	|		|	|			|	 |			|  |	|				 |
//		 |	|		|    |			| |		| 	|		|	|			|	 |			|  |	|	Periphiral	 |
//		 |	|  RAM  |<=> | S_AXI    | |<==>	|Bus| <==>	|	| M_AXI     | <= |   UART   |  | <= |	   (PC)   	 |
//		 |	|		|	 | Interface| |  	|   |		|	| Interface |	 |	 RX/TX  |  |	|				 |
//		 |	|		|	 |			| |		|   |		|	|			|	 |          |  |	|				 |
//		 |	|_______|	 |__________| |		|   |		|	|___________|    |__________|  |	|				 |
//		 |							  |		|   |		|								   |	|				 |
//		 |____________________________|		|___|		|__________________________________|	|________________|
//
//
//

module AXI_UART
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
	parameter MEMORY_DATA_WIDTH = 16,

)
(

	// GLOBAL SIGNALS
	input logic M_AXI_ACLK,								//P1	-	Clock
	input logic M_AXI_ARESETN,							//P2	-	Reset (active low)
	output logic Interrupt,								//P3	-	Interrupt


	// WRITE ADDRESS CHANNEL
	output logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,	//P4	-	Write Address
	output logic M_AXI_AWVALID,							//P5	-	Write Valid
	input logic M_AXI_AWREADY,							//P6	-	Write Ready


	// WRITE DATA CHANNEL
	output logic [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,	//P7	-	Write Data
	output logic [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTB,	//P8	-	Write Strobes
	output logic M_AXI_WAVLID,							//P9	-	Write Valid
	input logic M_AXI_WREADY,							//P10	-	Write Ready

	
	// WRITE RESPONSE CHANNEL
	input logic [1:0] M_AXI_BRESP,						//P11	-	Write Response (Faults/errors)
	input logic M_AXI_BVALID,							//P12	-	Write Response Valid
	output logic M_AXI_BREADY,							//P13	-	Write Response Ready

	// READ ADDRESS CHANNEL
	output logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,	//P14	-	Read Address
	output logic M_AXI_ARVALID,							//P15	-	Read Address Valid
	input logic M_AXI_ARREADY,							//P16	-	Read Address Ready


	// READ DATA CHANNEL
	input logic [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_RDATA,	//P17	-	Read Data 
	input logic [1:0] M_AXI_RRESP,						//P18	-	Read Response (Faults/errors)
	input logic M_AXI_RVALID,							//P19	-	Read Valid
	output logic M_AXI_RREADY,							//P20	-	Read Ready


	input logic RX,										//P21	-	Recieve 
	output logic TX,									//P22	-	Transmit 
	
	//==========================UART INPUT SIGNALS================================

	
	input logic UART_RX_I,								//RX input to UART form HOST
	input logic Initialize,								//TODO
	input logic Enable									//TODO


);



logic [MEMORY_ADDR_WIDTH-1:0] SRAM_address;	//number of bits needed to address embedded mem.
logic [MEMORY_DATA_WIDTH-1:0] SRAM_write_data;

// UART reciever inst.
// Recieves data from host PC/Periphiral through RX pin
// Packs them into 2 byte packets
// And writes data to SRAM
UART_SRAM_interface UART_SRAM_interface (
	.Clock(M_AXI_ACLK),
	.Resetn(M_AXI_ARESETN), 

	.UART_RX_I(UART_RX_I),
	.Initialize(Initialize),
	.Enable(Enable),
   
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.Frame_error(Frame_error)
);


//Notes: 
//	- Back pressure
//		- In the case where there is data that is ready to be written to the
//			SRAM through the AXI interface, but the SRAM is not ready, some back
//			pressure must be exerted on the UART (from the ) to prevent it from recieving more
//			data that cannot be used or stored.
//		- Hence, the Enable signal must be toggled accordingly. 
//
//


enum logic [3:0] {
	S_IDLE,
	S_RECIEVE_BYTES,
	S_READY_VALID_WAIT,
	S_WRITE
} S_AXI_UART;


always_ff @(posedge S_AXI_ACLK) begin
	if(!M_AXI_ARESETN) begin
		//TODO add resets
	end else begin
		case(S_AXI_UART): begin
			
			S_IDLE: begin
				
			end

			S_RECIEVE_BYTES: begin	//RX port open. UART recieving data
				
			end

			S_READY_VALID_WAIT: begin	//Data is complete. Wait for write opportunity.
				
			end

			S_WRITE: begin	//Perform write to slave
				
			end

		endcase
	end
end


endmodule
