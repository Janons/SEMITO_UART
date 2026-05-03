`default_nettype none

module topModule (
    input  wire i_clk,
    input  wire i_reset_n,
    input  wire uartRx,
    output wire o_uart_tx,
    output wire o_led
);

    // Reset
    reg [3:0] reset_cnt = 4'd0;
    wire power_on_reset = (reset_cnt < 4'hF);

    always @(posedge i_clk) begin
        if (power_on_reset)
            reset_cnt <= reset_cnt + 1'b1;
    end

    wire global_reset = power_on_reset || !i_reset_n;

    // Receiver
    wire [7:0] rx_data;
    wire rx_ready;

    receiver my_rx (
        .clk(i_clk),
        .uart_rx(uartRx),
        .rst_n(!global_reset),
        .data(rx_data),
        .data_ready(rx_ready)
    );

    // New transmitter interface
    wire tx_ready;
    wire tx_idle;
    reg  tx_valid = 1'b0;
    reg [7:0] tx_data = 8'd0;

    txuart my_tx (
        .clk(i_clk),
        .rst_n(!global_reset),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .prescale(16'd234),
        .tx_ready(tx_ready),
        .txd(o_uart_tx),
        .tx_idle(tx_idle)
    );

    // Echo logic
    reg pending = 1'b0;
    reg [7:0] pending_data = 8'd0;

    always @(posedge i_clk) begin
        if (global_reset) begin
            tx_valid    <= 1'b0;
            tx_data     <= 8'd0;
            pending     <= 1'b0;
            pending_data <= 8'd0;
        end else begin
            tx_valid <= 1'b0;

            if (rx_ready) begin
                pending_data <= rx_data;
                pending      <= 1'b1;
            end

            if (pending && tx_ready) begin
                tx_data  <= pending_data;
                tx_valid <= 1'b1;
                pending  <= 1'b0;
            end
        end
    end

    // LED toggles only for ASCII 'A'
    reg led_reg = 1'b0;

    always @(posedge i_clk) begin
        if (global_reset)
            led_reg <= 1'b0;
        else if (rx_ready && rx_data == 8'h41)
            led_reg <= ~led_reg;
    end

    assign o_led = led_reg;

endmodule