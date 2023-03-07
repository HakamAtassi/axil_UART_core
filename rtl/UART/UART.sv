`include "../rtl/UART/RX_module/UART_receive_controller.sv"
`include "../rtl/UART/TX_module/UART_transmit_controller.sv"


module UART 
#(
    parameter C_BAUDRATE = 115_200,
    parameter C_SYSTEM_FREQ = 50_000_000
)
(
    input logic Clk,                 
    input logic Resetn,            

    // RX signals
    input logic RX,                   
    input logic rd_uart_en,        
    input logic Enable_rx,


    output logic [7:0] RX_data,       
    output logic Empty,            

    // TX signals
    input logic [7:0] TX_data,       
    input logic wr_uart_en,            

    output logic Full,            
    output logic TX                 

);




// bridge internal signals
logic baud_tick;

//UART reciever internal signals

logic baud_timer_in;

logic Overrun;
logic Frame_error;

//UART transmit controller
logic [7:0] w_data;
logic Enable_tx;




//==================================
// Module instantiations

bridge	// Baudrate tick generator
#(
	.C_BAUDRATE(C_BAUDRATE),
	.C_SYSTEM_FREQ(C_SYSTEM_FREQ)
)
UART_bridge
(
	.Clk(Clk),
	.Resetn(Resetn),

	.baud_tick(baud_tick)
);


UART_receive_controller UART_receive_controller (
	.Clk(Clk),
	.Resetn(Resetn),
	
	.Enable(Enable_rx),
	.Unload_data(rd_uart_en),

	.baud_tick(baud_tick),
	
	.RX_data(RX_data),
	.Empty(Empty),
	.Overrun(Overrun),
	.Frame_error(Frame_error),

	// UART pin	
	.UART_RX_I(RX)
);

UART_transmit_controller UART_transmit_controller (
	.Clk(Clk),
	.Resetn(Resetn),
	
	.Enable(Enable_tx),      
    .w_data(TX_data),  

	.baud_tick(baud_tick),	//output of baudrate timer
	
	// UART pin	
    .UART_TX_I(TX)     
);



/*

fifo
#(
    .DATA_WIDTH(8),
    .DATA_DEPTH (128),
    .MEM_TYPE(0)      // 0->regs, 1->blockmem
)
rx_fifo
(
    .clk(clk),
    .resetn(resetn),

    .data_in(data_in),
    .wr_en(wr_en),
    .rd_en(rd_en),

    .data_out(data_out),
    .full(full),
    .empty(empty),

);


fifo
#(
    .DATA_WIDTH(8),
    .DATA_DEPTH (128),
    .MEM_TYPE(0)      // 0->regs, 1->blockmem
)
tx_fifo
(
    .clk(clk),
    .resetn(resetn),

    .data_in(data_in),RX
    .wr_en(wr_en),
    .rd_en(rd_en),

    .data_out(data_out),
    .full(full),
    .empty(empty),

);

*/




endmodule