`default_nettype	none
//
// }}}
module txuart #(
		// {{{
		parameter	[30:0]	INITIAL_SETUP = 31'd868,
		//
		localparam 	[3:0]	TXU_BIT_ZERO  = 4'h0,
		localparam 	[3:0]	TXU_BIT_ONE   = 4'h1,
		localparam 	[3:0]	TXU_BIT_TWO   = 4'h2,
		localparam 	[3:0]	TXU_BIT_THREE = 4'h3,
		// localparam 	[3:0]	TXU_BIT_FOUR  = 4'h4,
		// localparam 	[3:0]	TXU_BIT_FIVE  = 4'h5,
		// localparam 	[3:0]	TXU_BIT_SIX   = 4'h6,
		localparam 	[3:0]	TXU_BIT_SEVEN = 4'h7,
		localparam 	[3:0]	TXU_PARITY    = 4'h8,
		localparam 	[3:0]	TXU_STOP      = 4'h9,
		localparam 	[3:0]	TXU_SECOND_STOP = 4'ha,
		//
		localparam 	[3:0]	TXU_BREAK     = 4'he,
		localparam 	[3:0]	TXU_IDLE      = 4'hf
		// }}}
	) (
		// {{{
		input	wire		i_clk, i_reset,
		input	wire	[30:0]	i_setup, //channging the UART BAUD RATE etc
            // i_setup[30] = 0 to use hardware flow control, 1 to ignore it
            // i_setup[29:28] = number of data bits (00=5, 01=6, 10=7, 11=8)
            // i_setup[27] = 1 to use two stop bits, 0 for one stop bit
            // i_setup[26] = 1 to use parity, 0 for no parity
            // i_setup[25] = 1 to use fixed parity, 0 for calculated parity
            // i_setup[24] = if fixed parity, this is the value of the parity bit.
            //               if calculated parity, this is the odd/even bit (1 for odd)
            // i_setup[23:0] = number of clocks per baud (e.g. 868 for 115200 baud with a 100MHz clock)

		input	wire		i_break,
		input	wire		i_wr,
		input	wire	[7:0]	i_data,
		// Hardware flow control Ready-To-Send bit.  Set this to one to
		// use the core without flow control.  (A more appropriate name
		// would be the Ready-To-Receive bit ...)
		input	wire		i_cts_n,
		// And the UART input line itself
		output	reg		o_uart_tx,
		// A line to tell others when we are ready to accept data.  If
		// (i_wr)&&(!o_busy) is ever true, then the core has accepted a
		// byte for transmission.
		output	wire		o_busy
		// }}}
	);

	// Signal declarations
	// {{{
	wire	[27:0]	clocks_per_baud, break_condition;
	wire	[1:0]	i_data_bits, data_bits;
	wire		use_parity, parity_odd, dblstop, fixd_parity,
			fixdp_value, hw_flow_control, i_parity_odd;
	reg	[30:0]	r_setup;
	assign	clocks_per_baud = { 4'h0, r_setup[23:0] };
	assign	break_condition = { r_setup[23:0], 4'h0 };
	assign	hw_flow_control = !r_setup[30];
	assign	i_data_bits     =  i_setup[29:28];
	assign	data_bits       =  r_setup[29:28];
	assign	dblstop         =  r_setup[27];
	assign	use_parity      =  r_setup[26];
	assign	fixd_parity     =  r_setup[25];
	assign	i_parity_odd    =  i_setup[24];
	assign	parity_odd      =  r_setup[24];
	assign	fixdp_value     =  r_setup[24];

	reg	[27:0]	baud_counter;
	reg	[3:0]	state;
	reg	[7:0]	lcl_data;
	reg	 r_busy, zero_baud_counter, last_state;



    initial r_busy = 1'b0;
    inital state = TXU_IDLE;

    //start the state machine
    always @(posedge i_clk)
    if (i_reset)
    begin
        r_busy <= 1'b1;
        state <= TXU_IDLE
    end

    endmodule