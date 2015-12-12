module LowFQueues (
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
reg [9:0] 		new_ptr, old_ptr, next_new;
reg [9:0]		read_ptr, next_read;
reg [9:0]		end_ptr;

// Declare status registers for high and low queues
//// Define low frequency Registers 
reg 			read;

// Define write sample counter
reg				wrt_en;		// Keeps track of every other valid signal
reg				wrt_ff;

// Define buffer for output data
reg [15:0] 	data_out;

/* ------ Instantiate the dual port modules -------------------------------------------------------- */
dualPort1024x16 i1024Port(.clk(clk),.we(wrt_en),.waddr(new_ptr),.raddr(read_ptr),.wdata(new_smpl),.rdata(data_out));

/* ------ Always Block to Update Pointers ---------------------------------------------------------- */
always @(posedge clk, negedge rst_n) begin 
	if(!rst_n) begin
		// Reset Pointers
		new_ptr 		<= 10'h000;
	end else if(wrt_en) begin
		// Set Pointers
		new_ptr 		<= new_ptr + 1;
	end
end

always @(posedge clk, negedge rst_n) begin 
	if(!rst_n) begin
		// Reset Pointers;
		old_ptr 		<= 10'h000;
	end else if(read_ptr == end_ptr) begin
		// Set Pointers
		old_ptr		<= old_ptr + 1;
	end
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		read_ptr <= 10'h000;
	else if(read_ptr == end_ptr)
		read_ptr <= old_ptr;
	else if(read)
		read_ptr <= read_ptr + 1;
	else
		read_ptr <= old_ptr;
end	

//Update Sequencing
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		sequencing <= 1'b0;
	else if(wrt_en & read)
		sequencing <= 1'b1;
	else if(read_ptr == end_ptr)
		sequencing <= 1'b0;
end
		
assign smpl_out 	= (sequencing) ? data_out : 16'h0000;

/* ------ Control for read/write pointers and empty/full registers -------------------------------- */
assign end_ptr	= old_ptr + 10'd1020;
always @(posedge clk, negedge rst_n) 
	if(!rst_n)
		read <= 1'b0;
	else if(new_ptr == 10'd1020 && wrt_en)
		read <= 1'b1;	

/* ------ Manage Queue Counters ------------------------------------------------------------------- */
assign wrt_en = (wrt_ff & valid_rise);

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		wrt_ff <= 1'b0;
	else if(valid_rise)
		wrt_ff <= ~wrt_ff;
end

endmodule