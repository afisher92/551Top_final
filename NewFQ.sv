module NewFQ (
	input 		clk, rst_n,
	input signed [15:0] 	new_smpl,
	input 		valid_rise,
	input		valid_fall,
	output signed [15:0] 	smpl_out,
	output reg	sequencing
);

/* ------ Define any internal variables ------------------------------------------------------------- */
/*	Pointers designated as 'new' signify where the array is going to be written to
	Pointers designated as 'old' signify where the array is going to read from */

// Declare pointers for high band and low band queues
reg [9:0] 		new_ptr, old_ptr;
reg [9:0]		read_ptr;
reg [9:0]		end_ptr;

// Declare status registers for high and low queues
//// Define low frequency Registers 

// Define write sample counter
reg				wrt_en;		// Keeps track of every other valid signal

// Define States
typedef enum reg [2:0] {IDLE, WAIT, WRITE, READ} state_t;
state_t state, nxt_state;

/* ------ Instantiate the dual port modules -------------------------------------------------------- */
dualPort1024x16 i1024Port(.clk(clk),.we(wrt_en),.waddr(new_ptr),.raddr(read_ptr),.wdata(new_smpl),.rdata(smpl_out));

/* ------ Define State Machine --------------------------------------------------------------------- */
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
		
always_comb begin
	case(state)
		IDLE : begin
			if(valid_fall) // Wait for valid sample and the write trigger
				nxt_state = WRITE;
			else
				nxt_state = IDLE;
			old_ptr = 10'h000;
			new_ptr = 10'h000;
			end_ptr = old_ptr + 10'h3FC;
			read_ptr = old_ptr;
			wrt_en = 1'b0;
			sequencing = 1'b0;
		end
		WAIT :	begin// Allow registers to update and permeate
			if(valid_fall)
				nxt_state = WRITE;
			else 
				nxt_state = WAIT;
			wrt_en = 1'b1;
		end
		WRITE : begin
			wrt_en = 1'b0; // Reset wrt_en on 
			if(new_ptr == end_ptr + 1)
				nxt_state = READ;
			else 
				nxt_state = WAIT;
			new_ptr <= new_ptr + 1;
		end
		READ : begin
			sequencing = 1'b1;
			if(read_ptr == end_ptr)
				nxt_state = WAIT;
			else 
				nxt_state = READ;
			read_ptr = read_ptr + 1;
		end
		default : 
				nxt_state = IDLE;
	endcase
end

/* ------  Manage Pointers ------------------------------------------------------------------------- */
		
endmodule