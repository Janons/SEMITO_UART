//detect the start bit
//we wait for a baud and a half
//baud rate is 115200

module receiver (
    input clk,
    input uart_rx,
    output reg [7:0] data,
    output reg data_ready
);

localparam  IDLE = 4'd0,
            START = 4'd1,
            BIT0 = 4'd2,
            BIT1 = 4'd3,
            BIT2 = 4'd4,
            BIT3 = 4'd5,
            BIT4 = 4'd6,
            BIT5 = 4'd7,
            BIT6 = 4'd8,
            BIT7 = 4'd9,
            STOP = 4'd10;

localparam clock_per_baud = 234;

reg ck_uart;
reg q_uart;
reg [9:0] baud_counter;
reg [3:0] state; //we should be able to display which step we are in

initial {ck_uart, q_uart} = -1; //we initialize these values to -1
always @(posedge clk) //synchronization
    {ck_uart, q_uart} <= {q_uart, uart_rx}; //q_uart is the most recent, ck_uart is the synchronized bit we consider

initial baud_counter = 0;
always @(posedge clk) begin //timing and initialization for baud
    if (state == IDLE) begin  
        baud_counter <= 0; 
        state <= IDLE;
        if (!ck_uart) begin
            state <= START;
            baud_counter <= (clock_per_baud - 1'b1) + (clock_per_baud / 2); //we initialize with 1.5 bauds (this is our initial delay)   
        end
    end else if (baud_counter == 0) begin
        state <= state + 1;
        if (state >= STOP) begin
            state <= IDLE;
            baud_counter <= 0;
        end else begin
            baud_counter <= clock_per_baud - 1'b1; //we reset to 1 baud
        end
    end else begin
        baud_counter <= baud_counter - 1'b1;
    end
end

always @(posedge clk) begin //we insert the new data
    if ((baud_counter == 0) && (state >= BIT0) && (state <= BIT7)) begin
        data <= {ck_uart, data[7:1]};
    end
end

initial data_ready = 0; 
always @(posedge clk) begin //data ready output
    data_ready <= (baud_counter == 0) && (state == STOP); 
end

endmodule