module fifo #(
    parameter DATA_W = 8, 
    parameter ADDR_W = 6
)(
    input wire clk,
    input wire rst_n,

    input wire wr,
    input wire rd,
    output wire [DATA_W-1 : 0] rd_data,
    input wire  [DATA_W-1 : 0] wr_data,
    
    output wire empty,
    output wire full
);

    // Fixed Memory array width sizing [DATA_W-1 : 0] (8 bits)
    reg [DATA_W-1 : 0] fifo_mem [0 : (2**ADDR_W)-1];
    
    reg [ADDR_W-1 : 0] wr_addr_cur, wr_addr_next;
    reg [ADDR_W-1 : 0] rd_addr_cur, rd_addr_next;
    
    reg full_reg, empty_reg;
    reg full_next, empty_next;
    
    wire wr_en;
    wire rd_en;

    // Conditions to protect boundaries
    assign wr_en = wr && ~full_reg;
    assign rd_en = rd && ~empty_reg;

    // Memory write block
    always @(posedge clk) begin
        if (wr_en) begin
            fifo_mem[wr_addr_cur] <= wr_data;
        end
    end
    
    // Direct assignment to bypass internal clock read latency delay loops
    assign rd_data = fifo_mem[rd_addr_cur];

    // Corrected sequential block to look for negedge rst_n
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_addr_cur <= 0;
            rd_addr_cur <= 0;
            full_reg    <= 1'b0;
            empty_reg   <= 1'b1; // A reset FIFO is empty by default
        end else begin
            wr_addr_cur <= wr_addr_next;
            rd_addr_cur <= rd_addr_next;
            full_reg    <= full_next;
            empty_reg   <= empty_next;
        end
    end

    // Combinational pointer generation block
    always @(*) begin
        wr_addr_next = wr_addr_cur;
        rd_addr_next = rd_addr_cur;
        full_next    = full_reg;
        empty_next   = empty_reg;
        
        // Switched from raw inputs to protected enable flags
        case({rd_en, wr_en}) 
            2'b01: // Valid Write
                begin   
                    wr_addr_next = wr_addr_cur + 1;
                    empty_next   = 1'b0; // If we write, it cannot be empty
                    if (wr_addr_next == rd_addr_cur) begin
                        full_next = 1'b1;
                    end
                end
            2'b10: // Valid Read
                begin 
                    rd_addr_next = rd_addr_cur + 1;
                    full_next    = 1'b0; // If we read, it cannot be full
                    if (rd_addr_next == wr_addr_cur) begin
                        empty_next = 1'b1;
                    end
                end
            2'b11: // Simultaneous Read and Write
                begin
                    rd_addr_next = rd_addr_cur + 1;
                    wr_addr_next = wr_addr_cur + 1;
                    // Status flags (empty/full) stay identical because count doesn't change
                end
            default: ; // Do nothing
        endcase
    end
    
    assign full  = full_reg;
    assign empty = empty_reg;

endmodule