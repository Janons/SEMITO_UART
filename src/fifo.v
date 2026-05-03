module fifo (parameter DATA_W = 8)(
    input wire clk,
    input wire i_wr,
    input wire i_data,
    input reg i_rd,
    output reg o_data,
    output reg o_empty
);

//fifo memory
reg[7:0] fifo_mem [0:63];
reg [6:0] wr_addr;
reg[6:0] rd_addr;

//conditions
assign w_wr = i_wr && !o_full;
assign w_rd = i_rd && !o_empty;

//fifo memory
initial wr_addr = 0;
always @(posedge clk) begin
    if (w_wr)
        wr_addr <= wr_addr +1 // if we do writing, we increment the writing by one
end

always @(posedge clk) begin

    if (w_wr)
        fifo_mem[wr_addr] <= i_data;


    end

endmodule