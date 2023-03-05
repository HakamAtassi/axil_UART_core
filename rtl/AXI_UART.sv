// AXI UART
// May not be entirely AXI compliant. Use with caution.
//
//
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
//



module AXI_UART
#(

	parameter C_FAMILY = "virtex6",
	parameter C_S_AXI_ACLK_FREQ_HZ = 100000000,
	
	parameter C_S_AXI_ADDR_WIDTH = 4,
	parameter C_S_AXI_DATA_WIDTH = 32,
	parameter C_S_AXI_PROTOCOL = "AXI4LITE",

	parameter C_BAUDRATE = 9600,
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
	input logic S_AXI_AWVALID,							//P5	-	Write Valid
	output logic S_AXI_AWREADY,							//P6	-	Write Ready


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
	input logic S_AXI_RREADY,							//P20	-	Read Ready


	input logic UART_RX_I,								//P21 	-	input to UART from HOST
	output logic TX,									//P22	-	Transmit 
	
	//==========================UART INPUT SIGNALS================================
	
	input logic UART_initialize,						//P23	-	TODO
	output logic UART_enable							//P24	-	TODO 

);



logic [MEMORY_ADDR_WIDTH-1:0] SRAM_address;	//number of bits needed to address embedded mem.
logic [MEMORY_DATA_WIDTH-1:0] SRAM_write_data;
logic Initialize;




logic write_valid;	// Is the current write data/address "AXI" valid	
assign write_valid = S_AXI_AWVALID && S_AXI_WAVALID;	//TODO: missing signals?

logic write_ready;	// Is the slave "AXI" ready for a write operation
assign write_ready = S_AXI_AWREADY && S_AXI_WREADY;



// UART reciever inst.
// Recieves data from host PC/Periphiral through RX pin
// Packs them into 2 byte packets
// And writes data to SRAM

/*
UART_SRAM_interface UART_SRAM_interface (
	.Clock(S_AXI_ACLK),
	.Resetn(S_AXI_ARESETN), 

	.UART_RX_I(UART_RX_I),
	.Initialize(UART_initialize),
	.Enable(UART_enable),
   
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.Frame_error(Frame_error)
);
*/



enum logic [3:0] {
	S_IDLE,
	S_RECIEVE_WORDS	//TODO: Parameterize word size
} S_AXI_UART;





always_ff @(posedge S_AXI_ACLK) begin
	if(!S_AXI_ARESETN) begin
		
		//WRITE ADDRESS CHANNEL
		S_AXI_AWADDR<={C_S_AXI_ADDR_WIDTH{0}}; 	//TODO: number of bits is a param??
		S_AXI_AWVALID<=1'b0;

		//WRITE DATA CHANNEL
		S_AXI_WDATA<=SRAM_write_data;
		S_AXI_WSTB<={C_S_AXI_DATA_WIDTH{1}};	//Mask with all 1s (normal write, no strobe)
		S_AXI_WAVALID<=1'b0;

		// WRITE RESPONSE CHANNEL
		S_AXI_BREADY<=1'b0;	

		// READ ADDRESS CHANNEL
		S_AXI_ARADDR<={C_S_AXI_ADDR_WIDTH{0}};
		S_AXI_ARVALID<=1'b0;

		// READ DATA CHANNEL
		S_AXI_RREADY<=1'b0;

		

	end else begin
		case(S_AXI_UART)
			
			S_IDLE: begin
				if(UART_enable==1'b1) begin		//Start UART transmission
				end
			end

			S_RECIEVE_WORDS: begin	//RX port open. UART recieving data

			end

		endcase
	end
end


endmodule
