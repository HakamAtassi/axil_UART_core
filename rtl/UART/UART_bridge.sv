// Probably some sort of timer to sync up tx and rx modules of the uart

module bridge
#(
    parameter C_BAUDRATE = 115200,
    parameter C_SYSTEM_FREQ = 50_000_000
)
(
    input clk,
    input resetn,

    output baud_tick
);

parameter COUNTER_MAX = C_SYSTEM_FREQ / C_BAUDRATE;
parameter COUNTER_WIDTH = $clog2(COUNTER_MAX);


`ifdef SIMULATION             // note: we must adjust the TB as well
  `define RX_CLOCK_RATE 10'd6 // this is approx 7 pulses at 57.6 MHz 
 `else
  `define RX_CLOCK_RATE COUNTER_MAX
`endif

reg [(COUNTER_WIDTH-1):0] baud_counter;

always_ff @(posedge clk, negedge resetn) begin
    baud_counter<=baud_counter+1;
    baud_tick<=1'b0;

    if(baud_counter=COUNTER_MAX-1)
        baud_tick<=1'b1;
end



endmodule