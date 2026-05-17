module fifo #(parameter DATA_W = 8, 
            parameter ADDR_W = 6
    )(
    input wire clk,
    input wire rst_n,

    input wire wr,
    input wire rd,
    output wire [DATA_W-1 : 0] rd_data
    input wire [DATA_W-1 : 0] wr_data 
    
    output wire empty,
    output wire full
);

//fifo memory, we chose that 64 bytes are enough
reg[DATA_W : 0] fifo_mem [2**ADDR_W - 1];
reg[ADDR_W-1 : 0] wr_addr_cur, wr_addr_succ, wr_addr_next;
reg[ADDR_W-1 : 0] rd_addr_cur, rd_addr_succ, rd_addr_next;
reg[DATA_W : 0] read_reg;
reg full_reg, empty_reg, full_next, empty_next;
wire wr_en;
wire rd_en;

//conditions
assign wr_en = wr && ~full;
assign rd_en = rd && ~empty;

always @(posedge clk) begin
    if (wr_en) begin
        fifo_mem[wr_addr_cur] <= wr_data;
    end else if (rd_en) begin
        read_reg <= fifo_mem[rd_addr_cur];
    end
end
assign rd_data = read_reg;

//fifo memory
initial wr_addr = 0;
always @(posedge clk, posedge rst_n) begin
    if (rst_n) begin
        wr_addr_cur <= 0;
        rd_addr_cur <= 0;
        full_reg <= 0;
        empty_reg <= 0;
    end else if (clk) begin
        wr_addr_cur <= wr_addr_next;
        rd_addr_cur <= rd_addr_next;
        full_reg <= full_next;
        empty_reg <= empty_next;
    end
end

//now the logic for the next clock cycle prep
always @(*) begin
    wr_addr_succ = wr_addr_cur + 1;
    rd_addr_succ = rd_addr_cur + 1;
    wr_addr_next = wr_addr_cur; //this allows us to do the following: if we don't read/write, the next values are untouched
    rd_addr_next = rd_addr_cur; //if we read/write, we modify the next values 
    full_next = full_reg;
    empty_next = empty_reg; //same logic for these
    case({rd, wr}) 
        2'b01: //we write
            begin   
                if (~full_next) begin
                    wr_addr_next = wr_addr_succ;
                    empty_next = 1'b0;
                    if (wr_addr_next == rd_addr_cur) begin
                        full_next = 1'b1;
                    end
                end
            end
        2'b10: 
            begin //we read
                if (~empty_next) begin
                    rd_addr_next = rd_addr_succ;
                    full_next = 1'b0;
                    if (rd_addr_next == wr_addr_cur) begin
                        empty_next = 1'b0;
                    end
                end
            end
        2'b11: //we read AND write
            begin
                rd_addr_next = rd_addr_succ;
                wr_addr_next = wr_addr_succ;
            end
    endcase
end
assign full = full_reg;
assign empty = empty_reg;
endmodule