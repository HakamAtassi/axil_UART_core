//`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


`ifdef SIMULATION             // note: we must adjust the TB as well
  `define RX_CLOCK_RATE 10'd6 // this is approx 7 pulses at 57.6 MHz 
 `else
  `define RX_CLOCK_RATE 10'd434
`endif

`include "define_state.h"

module UART_receive_controller (
	input logic Clock_50,
	input logic Resetn,
	
	input logic Enable,        //good
	input logic Load_data,     //good
    input logic [7:0] w_data,  //good
	
	output logic Full,          //good

	output logic Overrun,       //??
	output logic Frame_error,   //??

	// UART pin	
    output logic UART_TX_I,            //good
);





endmodule
