/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

//`timescale 1ns/100ps
/*
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif
*/
// by enabling lower RX_CLOCK_RATE in simulation we can speed-up the verification
// note: the generator of UART bits in the testbench (TB) will need to be adjusted

`ifdef SIMULATION             // note: we must adjust the TB as well
  `define RX_CLOCK_RATE 10'd6 // this is approx 7 pulses at 57.6 MHz 
 `else
  `define RX_CLOCK_RATE 10'd434
`endif

//`include "define_state.h"


//sample at 16x the baudrate
//sampling reg goes from 0->7, samples, then resets
//then that same counter goes from 0->15, and when 15, it samples. 

//ie: 

//                       _____       _____
//	     signal   ______/     \_____/     \_____...	
//   sampling     ...^.....^.....^.....^.....^....





module UART_receive_controller #
(
    parameter C_BAUDRATE = 115_200,
    parameter C_SYSTEM_FREQ = 50_000_000
)

(
	input logic Clk,
	input logic Resetn,
	
	input logic Enable,
	input logic Unload_data,

	input logic baud_tick,
	
	output logic [7:0] RX_data,
	output logic Empty,
	output logic Overrun,
	output logic Frame_error,

	// UART pin	
	input logic UART_RX_I
);


parameter COUNTER_MAX = C_SYSTEM_FREQ / C_BAUDRATE;
parameter COUNTER_WIDTH = $clog2(COUNTER_MAX);

reg [3:0] tick_count;


//RX_Controller_state_type RXC_state;

logic [7:0] data_buffer;
logic [9:0] clock_count;
logic [2:0] data_count;
logic RX_data_in;


enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RXC_state;



// UART RX Logic
always_ff @ (posedge Clk or negedge Resetn) begin
	if (!Resetn) begin
		data_buffer <= 8'h00;
		RX_data <= 8'h00;
		clock_count <= 10'h000;
		data_count <= 3'h0;
		Frame_error <= 1'b0;
		Overrun <= 1'b0;
		Empty <= 1'b1;
		RXC_state <= S_RXC_IDLE;
		RX_data_in <= 1'b0;

		tick_count<=1'b0;
	end else begin
		// Synchronize the asynch signal
		RX_data_in <= UART_RX_I;
		
		// Unload the data
		if (Unload_data) Empty <= 1'b1;

		case (RXC_state)
		S_RXC_IDLE : begin
			if (Enable) begin
				// Uart receiver is enabled
				if (RX_data_in == 1'b0) begin
					// Start bit detected
					RXC_state <= S_RXC_SYNC;
					clock_count <= 10'h000;
					data_count <= 3'h0;
					Frame_error  <= 1'b0;
					Overrun   <= 1'b0;
				end
			end
		end
		S_RXC_SYNC: begin
			// Sync the counter for the correct time to sample for UART data on the serial interface
			if ((tick_count == 4'd7) && RX_data_in == 1'b0) begin
				// Finish sync process
				clock_count <= 10'h000;
				data_count <= 3'h0;
				data_buffer <= 8'h00;
				tick_count<=4'b0;
				RXC_state <= S_RXC_ASSEMBLE_DATA;
			end else begin
				// If the Start bit does not stay on 1'b0 during synchronization
				// it will fail this sync process			
				if (RX_data_in == 1'b0 && baud_tick==1'b1) tick_count <= tick_count + 4'b001;
				//else RXC_state <= S_RXC_IDLE;
			end
		end
		S_RXC_ASSEMBLE_DATA: begin
			// Assembling the 8 bit serial data onto data buffer
			if (tick_count == 4'd14) begin
				// Only sample the data at the middle of transmission
				data_buffer <= {RX_data_in, data_buffer[7:1]};
				tick_count <= 4'b0; 
				if (data_count == 3'h7) 
					// Finish assembling the 8 bit data
					RXC_state <= S_RXC_STOP_BIT;
				else data_count <= data_count + 3'h1;   
			end else begin
				if(baud_tick ==1'b1)
					tick_count <= tick_count + 4'b1;
			end
		end
		S_RXC_STOP_BIT: begin
			// Sample for stop bit here
			if (tick_count == 4'd14) begin
				RXC_state <= S_RXC_IDLE;
				if (RX_data_in == 1'b0) begin
					// If stop bit is not 1'b1, this 8 bit data is corrupted
					Frame_error <= 1'b1;
				end else begin
					Empty <= 1'b0;
					Frame_error <= 1'b0;

					// Check if last data has been unloaded or not
					Overrun  <= (Empty) ? 1'b0 : 1'b1;
					
					// Put the new data to the output
					RX_data  <= data_buffer;
				end
			end else begin
				if(baud_tick ==1'b1)
						tick_count <= tick_count + 4'b1;
			end
		end
		default: RXC_state <= S_RXC_IDLE;
		endcase
	end
end

endmodule
