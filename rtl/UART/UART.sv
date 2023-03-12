`include "../rtl/UART/RX_module/UART_receive_controller.sv"
`include "../rtl/UART/TX_module/UART_transmit_controller.sv"
`include "../rtl/UART/FIFO/fifo.sv"


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
    input logic wr_uart_en,  // enable a write to the tx fifo

    output logic Full,            
    output logic TX                 

);


// bridge internal signals
logic baud_tick;

//UART reciever internal signals

logic baud_timer_in;

logic Overrun;
logic Frame_error;


bridge	// Baudrate generator
#(
	.C_BAUDRATE(C_BAUDRATE),
	.C_SYSTEM_FREQ(100_000_000) //TODO: vauge parameter
)
UART_bridge
(
	.Clk(Clk),
	.Resetn(Resetn),

	.baud_tick(baud_tick)
);


//=========================================================================================
// ================================RX MODULE AND FIFO INST.================================
//=========================================================================================

wire [7:0] data_in_rx_fifo;

wire full_rx_fifo;
wire empty_rx_fifo;

wire write_en_rx_fifo;


// RX module wire assignments
//assign RX_data = data_out_rx_fifo;
assign write_en_rx_fifo = !Empty && !full_rx_fifo;  // fix rx module Empty signal name


fifo
#(
    .DATA_WIDTH(8),
    .DATA_DEPTH (128),
    .MEM_TYPE(0)      // 0->regs, 1->blockmem
)
rx_fifo
(
    .Clk(Clk),
    .Resetn(Resetn),

    .data_in(data_in_rx_fifo),
    .wr_en(!Empty),  //write to fifo when uart reciever is done TODO: how??
    .rd_en(rd_uart_en), //top level module read enable controlls the fifo

    .data_out(RX_data),
    .full(full_rx_fifo),
    .empty(empty_rx_fifo)
);

UART_receive_controller UART_receive_controller (
	.Clk(Clk),
	.Resetn(Resetn),
	
	.Enable(Enable_rx),
	.Unload_data(write_en_rx_fifo),

	.baud_tick(baud_tick),
	
	.RX_data(data_in_rx_fifo),
	.Empty(Empty),  //TODO: rename this signal

	.Overrun(Overrun),
	.Frame_error(Frame_error),

	// UART pin	
	.UART_RX_I(RX)
);



//=========================================================================================
// ================================TX MODULE AND FIFO INST.================================
//=========================================================================================

wire [7:0] data_out_tx_fifo;

wire full_tx_fifo;
wire empty_tx_fifo;

wire read_en_tx_fifo;

wire Ready_tx;

// Assignments

assign read_en_tx_fifo = Ready_tx && !empty_tx_fifo;

// TODO: make these params accessable to top level UART 


fifo
#(
    .DATA_WIDTH(8),
    .DATA_DEPTH (128),
    .MEM_TYPE(0)      // 0->regs, 1->blockmem
)
tx_fifo
(
    .Clk(Clk),
    .Resetn(Resetn),

    .data_in(TX_data),
    .wr_en(wr_uart_en),

    .rd_en(read_en_tx_fifo), 

    .data_out(data_out_tx_fifo),    
    .full(full_tx_fifo),
    .empty(empty_tx_fifo)

);


UART_transmit_controller UART_transmit_controller (
	.Clk(Clk),
	.Resetn(Resetn),
	
	.Enable(!empty_tx_fifo),
    .w_data(data_out_tx_fifo),  

	.baud_tick(baud_tick),	//output of baudrate timer
    .Ready(Ready_tx),
	
	// UART pin	
    .UART_TX_I(TX)     
);




endmodule