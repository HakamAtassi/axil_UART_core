// Will eventually be transformed to an alterra embedded memory...

module axi_slave(
	input logic clk,
	input logic reset_n,

	input logic S_AXIS_TVALID,
	input logic S_AXIS_TREADY,		//CHAGE TO OUTPUT
	
	input logic [31:0] S_AXIS_TDATA,
	input logic S_AXIS_TLAST,
	
	input logic S_AXIS_TID,		// Ignore (generally)
	input logic S_AXIS_TSTRB,	// Ignore (generally)
	input logic S_AXIS_TKEEP,	// Ignore (generally)
	input logic S_AXIS_TDEST,	// Ignore (generally)

	input logic S_AXIS_TUSER
);



always @(posedge clk) begin

//control ready...
//TODO: how should I do this?




end



always @(posedge clk) begin

	if(S_AXIS_TREADY && S_AXIS_TVALID) begin
	
		$display("Data: %0d", S_AXIS_TDATA);

		//TODO: store in embedded memory
	end

end


endmodule
