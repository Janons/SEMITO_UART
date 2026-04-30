
`timescale 1ns / 1ps

module uart_tx #(

	parameter data_width = 8,
)

(input wire clk,
input wire rst_n,
input wire tx_valid,
input wire tx_ready,
input wire [data_width-1:0] tx_data,
input wire [15:0] prescale,
)
reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [3:0] txByteCounter = 0;

//state machine states
localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;
localparam TX_STATE_DEBOUNCE = 4;

//states
always @(posedge clk or negedge rst_n) begin
	if (rst_n)
	begin
		txState <= TX_STATE_IDLE;
		txCounter <= 0;
		dataOut <= 0;
		txPinRegister <= 1;
		txBitNumber <= 0;
		txByteCounter <= 0;
	end
	else begin
		case (txState)
			TX_STATE_IDLE: begin
				if (tx_valid) begin
					txState <= TX_STATE_START_BIT;
					txCounter <= 0;
					dataOut <= {1'b1, tx_data}; // Add stop bit
					txPinRegister <= 0; // Start bit
					tx_ready <= 1;
				end
			else begin
				txPinRegister <= 1;
				tx_ready <= 0;
			end
			TX_STATE_START_BIT: begin
				txPinRegister <= 0; // Start bit
				if ((txCounter + 1) == (prescale << 3)) begin
					txState <= TX_STATE_WRITE;
					//dataOut <= {1'b1, tx_data}; // Add stop bit
					txCounter <= 0;
					txBitNumber <= 0;
					
				end
				else begin
					txCounter <= txCounter + 1;

				end
			end

			TX_STATE_WRITE: begin
				txPinRegister <= dataOut[0];
				if (txCounter + 1) == (prescale <<3) begin
					if (txBitNumber == 7) begin
						txState <= TX_STATE_STOP_BIT;
						txCounter <= 0;
						txBitNumber <= 0;
					end else begin
						txState <= TX_STATE_WRITE;
						dataOut <= dataOut >> 1; // Shift to get the next bit
						txCounter <= 0;
						txBitNumber <= txBitNumber + 1;
					end	
				end else begin
					tx_counter <= txCounter + 1;
				end
				
				end
			end

		endcase

end


endmodule