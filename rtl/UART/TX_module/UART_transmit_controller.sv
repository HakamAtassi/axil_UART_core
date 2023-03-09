module UART_transmit_controller (
	input logic Clk,
	input logic Resetn,
	
	input logic Enable,      
    input logic [7:0] w_data, 

	input logic baud_tick,	
	
	// UART pin	
    output logic UART_TX_I           
);


logic [7:0] data_shift_out;	//TODO: make parameter
logic TX_data_out;	//register the TX out
logic [2:0] data_count;

logic [9:0] clock_count;


logic [3:0] tick_count;



enum logic [1:0] {
	S_TX_IDLE,
	S_TX_START_BIT,
	S_TX_TRANSMIT_BITS,
	S_TX_STOP_BIT

} TX_state;


always_ff @ (posedge Clk, negedge Resetn) begin

	if(!Resetn) begin
		TX_state<=S_TX_IDLE;
		data_shift_out<=0;
		UART_TX_I<=1'b1;	//start at 0 or 1?
		tick_count<=4'd0;
		data_count<=3'd0;

		TX_data_out<=1'b1;
		
	end else begin

		UART_TX_I<=TX_data_out;	// TODO: needed??

		case(TX_state)
			
			S_TX_IDLE: begin
				TX_data_out<=1'b1;	// TX high when idle
				data_shift_out<=w_data;
				if(Enable) begin	//begin transmission
					TX_data_out<=1'b0;	//start bit
					TX_state<=S_TX_START_BIT;
				end
			end

			S_TX_START_BIT: begin
				if((tick_count == 4'd15 && baud_tick==1'b1)) begin
					TX_data_out<=data_shift_out[0];
					data_shift_out<=data_shift_out>>1;
					data_count<=3'b0;
					clock_count<=10'b0;
					TX_state<=S_TX_TRANSMIT_BITS;
				end
				if(baud_tick==1'b1) begin
					tick_count<=tick_count+4'd1;
				end
			end

			S_TX_TRANSMIT_BITS: begin
				if((tick_count == 4'd15 && baud_tick==1'b1)) begin
					TX_data_out<=data_shift_out[0];
					data_shift_out<=data_shift_out>>1;
					clock_count<=10'b0;
					data_count<=data_count+3'b1;
					if(data_count==3'd7) begin
						TX_state<=S_TX_STOP_BIT;
					end
				end
				if(baud_tick==1'b1) begin
					tick_count<=tick_count+4'd1;
				end
			end

			S_TX_STOP_BIT: begin
				TX_data_out<=1'b1;
				clock_count<=clock_count+10'b1;
				if((tick_count == 4'd15 && baud_tick==1'b1)) begin				
					TX_state<=S_TX_IDLE;	
					clock_count<=10'b0;
				end
				if(baud_tick==1'b1) begin
					tick_count<=tick_count+4'd1;
				end
			end


		endcase
	end
end





endmodule
