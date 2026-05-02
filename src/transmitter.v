`timescale 1ns / 1ps
module txuart #(
    parameter data_width = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  tx_valid,
    input  wire [data_width-1:0] tx_data,
    input  wire [15:0]           prescale,
    output reg                   tx_ready,
    output wire                  txd,
    output wire                  tx_idle
);

reg [1:0]  txState       = 0;
reg [24:0] txCounter     = 0;
reg [7:0]  dataOut       = 0;
reg        txPinRegister = 1;
reg [2:0]  txBitNumber   = 0;

assign txd    = txPinRegister;

localparam TX_STATE_IDLE      = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE     = 2;
localparam TX_STATE_STOP_BIT  = 3;

assign tx_idle = (txState == TX_STATE_IDLE);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        txState       <= TX_STATE_IDLE;
        txCounter     <= 0;
        dataOut       <= 0;
        txPinRegister <= 1;
        txBitNumber   <= 0;
        tx_ready      <= 0;
    end else begin
        case (txState)
            TX_STATE_IDLE: begin
                tx_ready <= 1;
                if (tx_valid) begin
                    txState       <= TX_STATE_START_BIT;
                    txCounter     <= 0;
                    dataOut       <= tx_data;
                    txPinRegister <= 0;
                    tx_ready      <= 0;
                end else begin
                    txPinRegister <= 1;
                    tx_ready      <= 0;
                end
            end

            TX_STATE_START_BIT: begin
                txPinRegister <= 0;
                tx_ready      <= 0;
                if (txCounter >= prescale - 1) begin
                    txState     <= TX_STATE_WRITE;
                    txCounter   <= 0;
                    txBitNumber <= 0;
                end else begin
                    txCounter <= txCounter + 1;
                end
            end

            TX_STATE_WRITE: begin
                txPinRegister <= dataOut[0];
                if (txCounter >= prescale - 1) begin
                    if (txBitNumber == data_width-1) begin
                        txState     <= TX_STATE_STOP_BIT;
                        txCounter   <= 0;
                        txBitNumber <= 0;
                    end else begin
                        dataOut     <= dataOut >> 1;
                        txCounter   <= 0;
                        txBitNumber <= txBitNumber + 1;
                    end
                end else begin
                    txCounter <= txCounter + 1;
                end
            end

            TX_STATE_STOP_BIT: begin
                txPinRegister <= 1;
                if (txCounter >= prescale - 1)begin
                    txState   <= TX_STATE_IDLE;
                    txCounter <= 0;
                    tx_ready  <= 1;
                end else begin
                    txCounter <= txCounter + 1;
                end
            end
        endcase
    end
end
endmodule