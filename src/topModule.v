module topModule (
    input  wire clk,
    input  wire rst_n,
    input  wire uartRx,
    output wire uart_txd,
    output wire o_led
);

//reg  [7:0] tx_data  = 0
wire       tx_valid;
wire      tx_ready;

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

//creating a delay register for tx_valid to ensure it aligns with the data output from the FIFO, which has a 1-cycle latency after asserting tx_fifo_rd. This helps maintain proper timing for the UART transmission.
reg tx_valid_r; 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_valid_r <= 1'b0;
    end else begin
        tx_valid_r <= tx_fifo_rd;  // Properly delays valid to match FIFO data output latency
    end
end

assign tx_valid = tx_valid_r;

assign tx_valid = tx_valid_r; // Use the registered version for timing stability

txuart #(.data_width(8)) uart_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_valid (tx_valid),
    .tx_data  (tx_fifo_dout), 
    .clk_per_baud (16'd234),   
    .tx_ready (tx_ready),
    .txd      (uart_txd)
);

assign rx_fifo_rd = !rx_fifo_empty; 

receiver my_rx (
    .clk       (clk),      // ← fixed: clk not i_clk
    .uart_rx   (uartRx),
    .rst_n     (rst_n),    // ← added
    .data      (rx_data),
    .data_ready(rx_ready)
);

reg [24:0] delay_counter = 0; // 25-bit counter can count up to ~33 million
reg [1:0]  senderState   = 0;

localparam LOAD  = 0;
localparam SEND  = 1;
localparam WAIT  = 2;
localparam DELAY = 3; // New state to pause between transmissions

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byteIndex     <= 0;
        tx_fifo_wr    <= 0;
        tx_fifo_din   <= 0;
        delay_counter <= 0;
        senderState   <= LOAD;
    end else begin
        case (senderState)
            
            LOAD: begin
                if (!tx_fifo_full) begin
                    tx_fifo_din <= message[byteIndex];
                    
                    senderState <= SEND;
                end
            end
            
            SEND: begin
                tx_fifo_wr  <= 1;
                senderState <= WAIT;
            end
            
            WAIT: begin
                tx_fifo_wr  <= 0;
                if (byteIndex == 1) begin
                    byteIndex   <= 0;
                    senderState <= DELAY; // Instead of repeating instantly, go to DELAY
                end else begin
                    byteIndex   <= byteIndex + 1;
                    senderState <= LOAD;
                end
            end
            
            DELAY: begin
                // 27,000,000 clock cycles = Exactly 1.0 Second of real-world time
                if (delay_counter >= 27000000) begin
                    delay_counter <= 0;
                    senderState   <= LOAD; // Restart the loop!
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end
            
            default: senderState <= LOAD;
        endcase
    end
end

// LED-LOGIC ─────────────────── for the reciever

reg led_reg = 0;

always @(posedge clk) begin   
    if (!rst_n)
        led_reg <= 0;
    else if (rx_fifo_rd && rx_fifo_dout == "A")
        led_reg <= ~led_reg;
end

assign o_led = led_reg;

endmodule