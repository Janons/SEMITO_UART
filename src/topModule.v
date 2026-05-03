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

reg [7:0] message [0:1];
reg [1:0] byteIndex = 0;

initial begin
    message[0] = 8'h48;  // 'H'
    message[1] = 8'h69;  // 'i'
end

txuart #(.data_width(8)) uart_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_valid (tx_valid),
    .tx_data  (tx_data),
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
        tx_valid    <= 0;
        tx_data     <= 0;
        senderState <= LOAD;
    end else begin
        case (senderState)
            LOAD: begin
                tx_data     <= message[byteIndex];
                tx_valid    <= 1;
                senderState <= SEND;
            end
            SEND: begin
                if (tx_ready) begin
                    tx_valid    <= 0;
                    senderState <= WAIT;
                end
            end
            WAIT: begin
                if (!tx_ready) begin    // ← wait for uart to go idle
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
    else if (rx_ready && rx_data == "A")
        led_reg <= ~led_reg;
end

assign o_led = led_reg;

endmodule