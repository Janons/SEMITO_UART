`default_nettype none

module top (
    input  wire i_clk,
    input  wire i_reset_n,
    output wire o_uart_tx,
    output wire o_led
);

    // --- 1. Power-on Reset & Timer (500ms) ---
    reg [3:0]  reset_cnt = 0;
    wire       power_on_reset = (reset_cnt < 4'hF);
    wire [30:0] simple_setup = 31'h400000EA;
    always @(posedge i_clk) if (power_on_reset) reset_cnt <= reset_cnt + 1'b1;

    wire       global_reset = power_on_reset || !i_reset_n;
    reg [23:0] timer_cnt = 0;
    reg        wr_pulse;

    always @(posedge i_clk) begin
        if (global_reset) begin
            timer_cnt <= 0;
            wr_pulse  <= 0;
        end else if (timer_cnt >= 24'd13_500_000) begin // 500ms
            timer_cnt <= 0;
            wr_pulse  <= 1;
        end else begin
            timer_cnt <= timer_cnt + 1'b1;
            wr_pulse  <= 0;
        end
    end

    // --- 2. The String Logic ---
    reg [3:0] char_index = 0;
    reg [7:0] string_rom [0:11];
    reg       sending = 0;

    initial begin
        string_rom[0] = "H"; string_rom[1] = "e"; string_rom[2] = "l";
        string_rom[3] = "l"; string_rom[4] = "o"; string_rom[5] = " ";
        string_rom[6] = "W"; string_rom[7] = "o"; string_rom[8] = "r";
        string_rom[9] = "l"; string_rom[10]= "d"; string_rom[11]= "!";
    end

    always @(posedge i_clk) begin
        if (global_reset) begin
            char_index <= 0;
            sending    <= 0;
        end else if (wr_pulse) begin
            sending    <= 1; // Start the sequence
        end else if (sending && !o_busy) begin
            if (char_index < 11)
                char_index <= char_index + 1'b1;
            else begin
                char_index <= 0;
                sending    <= 0; // Finished the string
            end
        end
    end

    // --- 3. UART Instance ---
    wire o_busy;
    txuart #(
        .INITIAL_SETUP(31'd234) // 115200 baud with a 50MHz clock
    ) my_tx (
        .i_clk(i_clk),
        .i_reset(global_reset),
        .i_setup(31'd235),
        .i_break(1'b0),
        // We only trigger 'i_wr' when we are in the 'sending' state 
        // AND the UART isn't already busy with a previous character.
        .i_wr(sending && !o_busy), 
        .i_data(string_rom[char_index]),
        .i_cts_n(1'b0),
        .o_uart_tx(o_uart_tx),
        .o_busy(o_busy)
    );

    assign o_led = o_uart_tx;

endmodule