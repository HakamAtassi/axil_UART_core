
module fifo
#(
    parameter DATA_WIDTH = 8,
    parameter DATA_DEPTH = 128,
    parameter MEM_TYPE = 0      // 0->regs, 1->blockmem
)
(

    input Clk,
    input Resetn,

    input logic [(DATA_WIDTH-1):0] data_in,
    input logic wr_en,
    input logic rd_en,

    output logic [(DATA_WIDTH-1):0] data_out,
    output logic full,
    output logic empty

);



parameter DATA_ADDR_WIDTH = $clog2(DATA_DEPTH);


logic [(DATA_WIDTH-1):0] buff [(DATA_DEPTH-1):0];    // TODO: add blockmem impl.

logic [(DATA_ADDR_WIDTH-1):0] front;
logic [(DATA_ADDR_WIDTH-1):0] back;



logic [(DATA_ADDR_WIDTH-1):0] dblnext;
logic [(DATA_ADDR_WIDTH-1):0] nxtread;


assign dblnext = back+2;
assign nxtread = front+1;

always_ff @(posedge Clk, negedge Resetn) begin

    if(!Resetn) begin
        empty<=1'b1;
        full<=1'b0;
        back<=0;
        front<={(DATA_ADDR_WIDTH-1){1'b0}};

    end else begin


        casez({wr_en,rd_en,!full,!empty})

            4'b01?1: begin  //normal read
                full<=1'b0;
                front<=front+1;
                data_out<=buff[front];
                empty<=(nxtread==back);   // 1 is added becase after the read is done, the fifo is empty
            end

            4'b101?: begin  //normal write
                full<=(dblnext==front);

                empty<=1'b0;
                buff[back]<=data_in;
                back<=back+1;
            end

            4'b11?0: begin  // simultaneously write and read when empty
                full<=1'b0;
                empty<=1'b0;

                //front<=front+1;
                back<=back+1;
                
                buff[back]<=data_in;
                data_out<=buff[front];
            end

            4'b11?1: begin  // simultaneously write and read when not empty
                full<=full; // 1 read and 1 write keeps buffer unchanged
                empty<=1'b0;    //wasnt empty before, wasnt empty now

                front<=front+1;
                back<=back+1;
                
                buff[back]<=data_in;
                data_out<=buff[front];


            end

        endcase
    end
end







endmodule