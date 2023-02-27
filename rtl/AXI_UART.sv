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
	output logic [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTB,	//P8	-	Write Data Strobes
	output logic M_AXI_WAVALID,							//P9	-	Write Data Valid
	input logic M_AXI_WREADY,							//P10	-	Write Data Ready

	
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


	output logic TX,									//P22	-	Transmit (not used)
	
	//==========================UART INPUT SIGNALS================================
	
	input logic UART_RX_I,								//RX input to UART from HOST
	input logic UART_initialize,						//TODO
	output logic UART_enable							//TODO Output?

);



logic [MEMORY_ADDR_WIDTH-1:0] SRAM_address;	//number of bits needed to address embedded mem.
logic [MEMORY_DATA_WIDTH-1:0] SRAM_write_data;
logic Initialize;




logic write_valid;	// Is the current write data/address "AXI" valid	
assign write_valid = M_AXI_AWVALID && M_AXI_WAVLID;	//TODO: missing signals?

logic write_ready;	// Is the slave "AXI" ready for a write operation
assign write_ready = M_AXI_AWREADY && M_AXI_WREADY;

// UART reciever inst.
// Recieves data from host PC/Periphiral through RX pin
// Packs them into 2 byte packets
// And writes data to SRAM
UART_SRAM_interface UART_SRAM_interface (
	.Clock(M_AXI_ACLK),
	.Resetn(M_AXI_ARESETN), 

	.UART_RX_I(UART_RX_I),
	.Initialize(UART_initialize),
	.Enable(UART_enable),
   
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.Frame_error(Frame_error)
);


//Notes: 
//	- Back pressure
//		- In the case where there is data that is ready to be written to the
//			SRAM through the AXI interface, but the SRAM is not ready, some back
//			pressure must be exerted on the UART to prevent it from recieving more
//			data that cannot be used or stored.


enum logic [3:0] {
	S_IDLE,
	S_RECIEVE_WORDS	//TODO: Parameterize word size
} S_AXI_UART;





always_ff @(posedge S_AXI_ACLK) begin
	if(!M_AXI_ARESETN) begin
		
		//WRITE ADDRESS CHANNEL
		M_AXI_AWADDR<={C_M_AXI_ADDR_WIDTH{0}}; 	//TODO: number of bits is a param??
		M_AXI_AWVALID<=1'b0;

		//WRITE DATA CHANNEL
		M_AXI_WDATA<=SRAM_write_data;
		M_AXI_WSTB<={C_M_AXI_DATA_WIDTH{1}};	//Mask with all 1s (normal write, no strobe)
		M_AXI_WAVLID<=1'b0;

		// WRITE RESPONSE CHANNEL
		M_AXI_BREADY<=1'b0;	

		// READ ADDRESS CHANNEL
		M_AXI_ARADDR<={C_M_AXI_ADDR_WIDTH{0}};
		M_AXI_ARVALID<=1'b0;

		// READ DATA CHANNEL
		M_AXI_RREADY<=1'b0;

		

	end else begin
		case(S_AXI_UART): begin
			
			S_IDLE: begin
				if(UART_enable==1'b1) begin		//Start UART transmission
					S_AXI_UART<=S_RECIEVE_WORDS;
				end
			end

			S_RECIEVE_WORDS: begin	//RX port open. UART recieving data

				/** AXI MASTER LOGIC **/

				// If write is valid and slave is ready => data can update
				// If write is valid and slave is not ready => "Hold" data (TODO: How?? buffer?)
				// If write is not valid and slave is ready	=> data can update
				// If write is not valid and slave is not ready => data can update


				M_AXI_AWVALID<=1'b0;
				M_AXI_WAVLID<=1'b0;
				if(!write_valid || write_ready) begin
					M_AXI_WDATA<=SRAM_write_data;
					M_AXI_AWADDR<=SRAM_address;	
				end


				if(SRAM_we_n==1'b1) begin
					// Make signals valid such that they are actually written

					M_AXI_AWVALID<=1'b1;
					M_AXI_WAVLID<=1'b1;

					//TODO: Overrun? Backpressure?
				end else if(SRAM_address=={MEMORY_ADDR_WIDTH{1}}) begin
					S_AXI_UART<=S_IDLE;
				end
			end


		endcase
	end
end


endmodule
