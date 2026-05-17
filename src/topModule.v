module topModule (
    input  wire clk,
    input  wire rst_n,
    input  wire uartRx,
    output wire uart_txd,
    output wire o_led
);

reg  [7:0] tx_data  = 0;
reg        tx_valid = 0;
wire       tx_ready;

wire [7:0] rx_data;    // ← internal wire, not port
wire       rx_ready;   // ← internal wire, not port

wire [7:0] rx_fifo_dout; // Out of FIFO
wire       rx_fifo_empty;
wire       rx_fifo_full;
wire       rx_fifo_rd;   // Tell FIFO to output next byte

reg  [7:0] tx_fifo_din = 0; // Data to push into TX FIFO
reg        tx_fifo_wr = 0; // Push command for TX FIFO
wire [7:0] tx_fifo_dout;     // Data coming out of TX FIFO
wire       tx_fifo_empty;
wire       tx_fifo_full;
wire       tx_fifo_rd;       // Pop command for TX FIFO

reg [7:0] message [0:1];
reg [1:0] byteIndex = 0;

initial begin
    message[0] = 8'h48;  // 'H'
    message[1] = 8'h69;  // 'i'
end

//tx fifo signals
fifo #(.DATA_W(8), .ADDR_W(6)) tx_fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .wr(tx_fifo_wr),
    .rd(tx_fifo_rd),
    .wr_data(tx_fifo_din),
    .rd_data(tx_fifo_dout),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full)
);

//rx fifo signals
fifo #(.DATA_W(8), .ADDR_W(6)) rx_fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .wr(rx_ready),
    .rd (rx_fifo_rd),
    .wr_data(rx_data),
    .rd_data(rx_fifo_dout),
    .empty(rx_fifo_empty),
    .full(rx_fifo_full)
);
assign tx_fifo_rd = (!tx_fifo_empty && tx_ready);
assign tx_valid   = tx_fifo_rd;

txuart #(.data_width(8)) uart_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_valid (tx_valid),
    .tx_data  (tx_fifo_dout), 
    .clk_per_baud (16'd234),    // ← fixed: 27MHz / (115200 × 8) = 29
    .tx_ready (tx_ready),
    .txd      (uart_txd)
);

receiver my_rx (
    .clk       (clk),      // ← fixed: clk not i_clk
    .uart_rx   (uartRx),
    .rst_n     (rst_n),    // ← added
    .data      (rx_data),
    .data_ready(rx_ready)
);

reg [1:0] senderState = 0;
localparam LOAD = 0;
localparam SEND = 1;
localparam WAIT = 2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byteIndex   <= 0;
        tx_fifo_wr  <= 0;
        tx_fifo_din <= 0;
        senderState <= LOAD;
    end else begin
        case (senderState)
            LOAD: begin
                if (!tx_fifo_full) //in the old version we wrote directly to uart, here we first write to fifo 
                tx_fifo_din <= message[byteIndex];
                tx_fifo_wr <= 1;
                senderState <= SEND;
            end
            SEND: begin
                if (tx_fifo_wr) begin
                    tx_fifo_wr  <= 0;
                    senderState <= WAIT;
                end
            end
            WAIT: begin
                if (!tx_fifo_wr) begin    // ← wait for uart to go idle
                    if (byteIndex == 1)
                        byteIndex <= 0;
                    else
                        byteIndex <= byteIndex + 1;
                    senderState <= LOAD;
                end
            end
        endcase
    end
end

reg led_reg = 0;

always @(posedge clk) begin   // ← fixed: clk not i_clk
    if (!rst_n)
        led_reg <= 0;
    else if (rx_fifo_rd && rx_fifo_dout == "A")
        led_reg <= ~led_reg;
end

assign o_led = led_reg;

endmodule