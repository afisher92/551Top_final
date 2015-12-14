////////////////////////////////////////////////////////////////////////
// Copied description from Hoffman's SPI_Master:					 //
// SPI master module that transmits and receives 16-bit packets     //
// cmd[15:0] is 16-bit packet that goes out on MOSI, rd_data[15:0] //
// is the 16-bit word that came back on MISO.                     //
// wrt is control signal to initiate a transaction. done is      //
// asserted when transaction is complete. SCLK is currently set //
// for 1:32 of clk (1.6MHz).                                   //
////////////////////////////////////////////////////////////////

module SPI_mstr(
	input clk,
	input rst_n,
	input wrt,
	input MISO,
	input [15:0] cmd,			// Data for master to send
	output reg done,				// Indicates that SPI transaction has completed
	output [15:0] rd_data,		// Data read from slave
	output SCLK,
	output reg SS_n,
	output MOSI
);

/* ------ Define state machine parameters --------------------------------- */
typedef enum reg[1:0] {IDLE,SHIFT,PORCH} state_t;
state_t state, nxt_state;

/* ------ Define any regs or wires ---------------------------------------- */
// Counters
reg [4:0] dec_cnt, shft_cnt;

// Output buffers
reg [15:0] shft_reg;

// Status flops
reg clr_done, set_done;

/* ------ Declare state machine outputs ----------------------------------- */
reg rst_cnt, en_cnt, shft;

/* ------ Define Output Signals ------------------------------------------- */
assign MOSI = shft_reg[15];
assign rd_data = shft_reg;

/* ------ Manage status registers ----------------------------------------- */
// Set Done and SS_n
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		done <= 1'b0;
		SS_n <= 1'b0;
	end else if(set_done) begin
		done <= 1'b1;
		SS_n <= 1'b1;
	end else if(clr_done) begin
		done <= 1'b0;
		SS_n <= 1'b0;
	end
end

/* ------ Run Counters ---------------------------------------------------- */
// dec_cnt keeps track of the time after the rise of SCLK to initiate bit shift
always @(posedge clk, negedge rst_n) 
	if(!rst_n)
		dec_cnt <= 5'h18;
	else if(rst_cnt)
		dec_cnt	<= 5'h18;
	else
		dec_cnt <= dec_cnt - 1;
		
assign SCLK = dec_cnt[4];

// Status counter to signify when shifting is complete
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		shft_cnt <= 5'h00;
	else if(en_cnt)
		shft_cnt <= shft_cnt + 1;

/* ------ Implement Shifting ---------------------------------------------- */
always @(posedge clk)
	if (wrt)
		shft_reg <= cmd;
    else if (shft)
		shft_reg <= {shft_reg[14:0],MISO};

/* ------ Implement State Machine ----------------------------------------- */
// Manage next state
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		state = IDLE;
	else 
		state = nxt_state;

// Run state machine
always @(*) begin
	rst_cnt = 0;
	en_cnt = 0;
	shft = 0;
	set_done = 0;
	clr_done = 0;
	nxt_state = IDLE;
	
	case (state)
		IDLE : begin
			rst_cnt = 1'b1;
			if (wrt) begin
				nxt_state = SHIFT;
				clr_done = 1'b1;
			end
			else 
				nxt_state = IDLE;
		end
		SHIFT : begin
			en_cnt = (dec_cntr==5'b11110) ? 1'b1 : 1'b0;
			shft = (dec_cntr==5'b11110) ? 1'b1 : 1'b0;
			if (shft_cnt[4])
				nxt_state = PORCH;
			else
				nxt_state = SHIFT;
		end
		PORCH : begin
			if (dec_cntr==5'b11000) begin
				nxt_state = IDLE;
				set_done = 1'b1;
			end
			else
				nxt_state = PORCH;
		end
		default : nxt_state = IDLE;
	endcase
end

endmodule
