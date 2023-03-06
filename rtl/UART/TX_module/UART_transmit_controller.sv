//`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


// some calculations:
// if baud rate is 115200 => baud clock generator must count at 
// (system clk freq)/(baudrate) = (50e6)/(115200) = 434.02 = ~434
//

`ifdef SIMULATION             // note: we must adjust the TB as well
  `define RX_CLOCK_RATE 10'd6 // this is approx 7 pulses at 57.6 MHz 
 `else
  `define RX_CLOCK_RATE 10'd434	
`endif

`include "define_state.h"



module UART_receive_controller (
	input logic clk,
	input logic Resetn,
	
	input logic Enable,        //good
    input logic [7:0] w_data,  //good

	input logic baud_timer_in,	//output of baudrate timer
	
	output logic Full,          //good

	output logic Overrun,       //??
	output logic Frame_error,   //??

	// UART pin	
    output logic UART_TX_I,            //good
);


logic [7:0] data_shift_out;	//TODO: make parameter
logic TX_data_out;	//register the TX out
logic [2:0] data_count;

logic [9:0] clock_count;


typedef enum logic [1:0] {
	S_TX_IDLE,
	S_TX_START_BIT,
	S_TX_TRANSMIT_BITS,
	S_TX_STOP_BIT

} TX_state;


always_ff @ (posedge clk, negedge Resetn) begin

	if(!Resetn) begin
		TX_state<=S_TX_IDLE;
		data_shift_out<=0;
		UART_TX_I<=1'b1;	//start at 0 or 1?
		
	end else begin

		UART_TX_I<=TX_data_out;	// TODO: needed??

		case(TX_state):
			
			S_TX_IDLE: begin
				TX_data_out<=1'b1;	// TX high when idle
				data_shift_out<=w_data;
				if(Enable) begin	//begin transmission
					TX_data_out<=1'b0;	//start bit
					TX_state<=S_TX_START_BIT;
				end
			end

			S_TX_START_BITS: begin
				if(clock_count==`RX_CLOCK_RATE-1) begin
					TX_data_out<=data_shift_out[0];
					data_shift_out<=data_shift_out>>1;
					data_count<=data_count+3'b1;
					clock_count<=10'b0;

					TX_state<=S_TX_TRANSMIT_BIT;
				end
				clock_count<=clock_count+10'b1;
			end

			S_TX_TRANSMIT_BITS: begin
				if(clock_count==`RX_CLOCK_RATE-1) begin
					TX_data_out<=data_shift_out[0];
					data_shift_out<=data_shift_out>>1;
					clock_count<=10'b0;
					data_count<=data_count+3'b1;
					
					TX_state<=S_TX_TRANSMIT_BIT;
					if(data_count==3'd7) begin
						TX_state<=S_TX_STOP_BIT;
					end
				end
				clock_count<=clock_count+10'b1;

			end

			S_TX_STOP_BIT: begin
				TX_data_out<=1'b1;
				clock_count<=clock_count+10'b1;
				if(clock_count==`RX_CLOCK_RATE-1) begin				
					TX_state<=S_TX_IDLE;	
					clock_count<=10'b0;
				end
			end
		endcase
	end
end





endmodule
