module HiFQueues (
	input 			clk, rst_n,
	input signed [15:0] 	new_smpl,
	input 			valid_rise,
	output signed [15:0] 	smpl_out,
	output reg			sequencing
);

/* ------ Define any internal variables ------------------------------------------------------------- */
/*	Pointers designated as 'new' signify where the array is going to be written to
	Pointers designated as 'old' signify where the array is going to read from */
	
reg [10:0] 		new_ptr, old_ptr;
reg [10:0]		read_ptr;

/* Define high frequency registers */
reg [10:0]		cnt;				//Counts how many addresses have samples writen to them
reg				wrt_en;
reg [15:0]		data_out;

/* Define Additional Counters */
reg [10:0]		read_cnt;

/* ------ Instantiate the dual port modules -------------------------------------------------------- */
dualPort1536x16 i536Port(.clk(clk),.we(valid_rise),.waddr(new_ptr),.raddr(read_ptr),.wdata(new_smpl),.rdata(data_out));

/* ------ Always Block to Update States ------------------------------------------------------------ */
// new_ptr manages the next available address to be written to
// Is updated at every valid signal
always @(posedge clk, negedge rst_n) begin 
	if(!rst_n)
		new_ptr  <= 11'h000;
	else if(valid_rise)
		new_ptr	 <= new_ptr + 1'b1;
	else if(new_ptr == 11'h600)
		new_ptr <= 11'h000;
end

// old_ptr holds the first address in the queue. 
always @(posedge clk, negedge rst_n) begin 
	if(!rst_n)
		old_ptr  <= 11'h000;
	else if(old_ptr == 11'h5FB)
		old_ptr <= 11'h000;
	else if(read_cnt == 11'h3FC)
		old_ptr	 <= old_ptr + 1'b1;
end

// read_ptr points to the address in memory that will be read
// This cycles through 1021 memory locations as quickly as possible
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		read_ptr <= 11'h000;
	else if(read_ptr >= 11'h5FF)
		read_ptr <= 11'h000;
	else if(sequencing)
		read_ptr <= read_ptr + 1'b1;
	else
		read_ptr <= old_ptr;
	
// sequencing is valid when there have been 1531 samples written 
// and a new valid signal has come in. It goes back to 0 when 
// 1021 samples have been read
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		sequencing <= 1'b0;
	else if(cnt == 11'h5FB & valid_rise)
		sequencing <= 1'b1;
	else if(read_cnt == 11'h3FC)
		sequencing <= 1'b0;

assign smpl_out   = (sequencing) ? data_out : 16'h0000;
/* ------ Manage Queue Counters ------------------------------------------------------------------- */
// cnt keeps track of the initial 1531 samples written to memory.
// Once set, it stays high until reset
always @(posedge clk, negedge rst_n) 
	if (!rst_n)
		cnt <= 11'h000;
	else if(cnt != 11'h5FB & valid_rise) begin
		cnt <= cnt + 1'b1;
	end
	
// Need a continuous write signal to manage counters and act as a state flag
// Is high as soon as first valid signal is input 
// Ensures we only write valid signals
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		wrt_en <= 1'b0;
	else if(valid_rise)
		wrt_en <= 1'b1;	

// Keeps track of how many samples have been read. Equivalent to end_ptr function
// found in the LowFQueues
always @(posedge clk)
	if(sequencing)
		read_cnt <= read_cnt + 1;
	else 
		read_cnt <= 11'h000;


endmodule
