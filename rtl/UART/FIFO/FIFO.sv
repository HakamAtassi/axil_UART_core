
module fifo
#(
    parameter DATA_WIDTH = 8,
    parameter DATA_DEPTH = 128,
    parameter MEM_TYPE = 0      // 0=>regs, 1=>blockmem
)
(

    input clk,
    input resetn,

    input logic [(DATA_WIDTH-1):0] data_in,
    input logic wr_en,
    input logic rd_en,

    output logic [(DATA_WIDTH-1):0] data_out,
    output logic full,
    output logic empty,

);

parameter DATA_ADDR_WIDTH = $clog2(DATA_DEPTH);


logic [(DATA_WIDTH-1):0] buff [(DATA_DEPTH-1):0];    // TODO: add blockmem impl.

logic [(DATA_ADDR_WIDTH-1):0] front;
logic [(DATA_ADDR_WIDTH-1):0] back;



always_ff @(posedge clk) begin

    if(!resetn) begin
        empty<=1'b0;
        full<=1'b0;
    end else begin

        case({wr_en,rd_en,full,empty})

            4'b100x: begin  //normal write
                buff[back]<=data_in;
                back<=back+1;
                full<=((back+2)==front);    // Calculate 1 clock early to overcome latency. 
                                            // Note, the FIFO has a capacity of N-1
            end

            4'b01x0: begin  //normal read
                data_out<=buff[front];
                front<=front-1;
                empty<=((back+1==front));

            end

            4'b11x0: begin  
                //if already empty, a read/write pair cant change status flags
                full<=1'b0;
                empty<=1'b0;
                data_out<=buff[front];
                buff[back]<=data_in;
            end
            
            4'b11x1: begin  
                //if already full, a read/write pair cant change status flags
                full<=1'b0;
                empty<=1'b1;
                data_out<=buff[front];
                buff[back]<=data_in;
            end

        endcase

    end

end







endmodule