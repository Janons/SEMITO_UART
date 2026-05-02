module topModule (
    input  wire clk,
    input  wire rst_n,   
    output wire uart_txd,
    output wire o_led      // ← add this
);

reg [7:0]  tx_data    = 0;
reg        tx_valid   = 0;
wire       tx_ready;
wire       tx_idle;
reg [7:0]  message [0:1];
reg [1:0]  byteIndex = 0;


assign o_led = uart_txd;   // ← LED mirrors TX line

initial begin
    message[0] = 8'h48;  // 'H'
    message[1] = 8'h69;  // 'i'
end

txuart #(.data_width(8)) uart_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_valid (tx_valid),
    .tx_data  (tx_data),
    .prescale (16'd234),
    .tx_ready (tx_ready),
    .txd      (uart_txd),
    .tx_idle  (tx_idle)
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
                if (tx_idle) begin
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

endmodule