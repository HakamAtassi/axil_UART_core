`timescale 1ns/100ps

`include "../rtl/UART/FIFO/fifo.sv"


module fifo_tb;


logic Clk;
logic Resetn;

logic [7:0] data_in;
logic wr_en;
logic rd_en;

logic [7:0] data_out;
logic full;
logic empty;


fifo
#(
    .DATA_WIDTH(8),
    .DATA_DEPTH(128),
    .MEM_TYPE(0)
)
fifo
(

    .Clk(Clk),
    .Resetn(Resetn),

    .data_in(data_in),
    .wr_en(wr_en),
    .rd_en(rd_en),


    .data_out(data_out),
    .full(full),
    .empty(empty)

);



task write_fifo(logic [7:0] word);
    if(!full) begin
        @(posedge Clk);
        wr_en<=1'b1;
        data_in<=word;
        @(posedge Clk);
        wr_en<=1'b0;
        @(posedge Clk);
    end else begin
        $display("write of %0d failed. Fifo full", word);
    end
endtask


task read_fifo;
    if(!empty) begin
        rd_en<=1'b1;
        @(posedge Clk);
        rd_en<=1'b0;
        @(posedge Clk);
        $display("%0d",data_out);
    end else begin
        $display("Read failed. Fifo empty");
    end
endtask



task write_and_read_fifo(logic [7:0] word);
	@(posedge Clk);
    wr_en<=1'b1;
    rd_en<=1'b1;
    data_in<=word;
	@(posedge Clk);
    rd_en<=1'b0;
    wr_en<=1'b0;
	@(posedge Clk);
    $display("%0d",data_out);

endtask


initial begin
	$dumpfile("fifo_tb");
	$dumpvars();
end


always begin
    Clk<=1'b1; #1; Clk<=1'b0; #1;
end

initial begin
	Resetn<=1'b1;
	@(posedge Clk);
	Resetn<=1'b0;
	@(posedge Clk);
	Resetn<=1'b1;

    rd_en<=1'b0;
end

/*
initial begin
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);

    for(int i=0;i<200;i=i+1) begin
        write_fifo(i);
    end

    // Now do read(s)
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);

   for(int i=0;i<200;i=i+1) begin
       read_fifo;
   end
end
*/


initial begin
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);
	@(posedge Clk);

    for(int i=0;i<128;i=i+1) begin
        write_fifo(i);
    end

    write_and_read_fifo(255);

   for(int i=0;i<200;i=i+1) begin
       read_fifo;
   end

   

//    write_fifo(42);
//    read_fifo;
    //write_and_read_fifo(42);


end



initial begin
    repeat(100_000) @(posedge Clk);
    $finish;
end


endmodule