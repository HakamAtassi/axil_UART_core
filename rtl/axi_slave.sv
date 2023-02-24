
module axi_master(
	input logic clk,
	input logic reset_n,
	
	output logic M_AXIS_TVALID,
	input logic M_AXIS_TREADY,
	
	output logic [31:0] M_AXIS_TDATA,
	output logic M_AXIS_TLAST,
	
	output logic M_AXIS_TID,	//ignore (generally)
	output logic M_AXIS_TSTRB,	//ignore (generally)
	output logic M_AXIS_TKEEP,	//ignore (generally)
	output logic M_AXIS_TDEST,	//ignore (generally)

	output logic M_AXIS_TUSER
);



logic next_valid_signal;


always @(posedge clk) begin
	if(reset_n==1'b0) begin
		M_AXIS_TVALID<=1'b0;
	end else if(!M_AXIS_TVALID || M_AXIS_TREADY) begin
		M_AXIS_TVALID <= next_valid_signal;	// valid can change UNLESS
		// There is a valid data packet that was not recieved by the slave
		// ie, Valid was high and ready was low => DONT CHANGE VALID (or risk
		// a dropped packet...)
	end
end








endmodule
