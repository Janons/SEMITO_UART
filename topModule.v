module top (
    input  wire i_clk,      // Pin 52 (27MHz)
    input  wire i_reset_n,  // Pin 4 (The "S1" button on the board)
    output wire o_uart_tx   // Pin 17
);

    wire [30:0] setup = 31'h700000EA; // 115200 baud @ 27MHz
    reg  [24:0] counter;
    reg         wr_pulse;

    // Send a character roughly every 0.5 seconds
    always @(posedge i_clk) begin
        counter <= counter + 1'b1;
        wr_pulse <= (counter == 24'h1FFFFFF); 
    end

    txuart my_tx (
        .i_clk(i_clk),
        .i_reset(!i_reset_n), // S1 is active-low, we need active-high
        .i_setup(setup),
        .i_break(1'b0),
        .i_wr(wr_pulse),
        .i_data(8'h47),       // ASCII 'G'
        .i_cts_n(1'b0),       // Always ready
        .o_uart_tx(o_uart_tx),
        .o_busy()
    );

endmodule


//just used to check the code of ZIP CPU