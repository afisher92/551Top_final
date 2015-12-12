/* -------------------------------------------------------------------------------------------------------------------------------------------------------------
Tests the circular queues functionality. The goal is to have a FIFO system that that can update and write continuously and independently.
***Test originally written for the low frequency queue exclusively***
The test executes as follows:
1. Initialize all the variables
2. Create a dummy queue to hold 1021 unique values that we can use to compare and measure length
3. Fill the actual queues with the dummy queue vales (Sampling does not occur here, the real queues MUST contain data values 0-1020 to accurately compare)
4. Test for matching data 
5. If control test passes, write a unique value (could be 1021, it'd be easy enough to keep track and generate new unique values) to the real queues (Just ONE value)
6. Read the full queue and compare how many data points are different than the dummy queue and that the last different output is the data that was just written
7. If that test passes, continue to do the same thing 1021 times (testing each time) until the real queues are entirely different from the dummy queue
8. If no test fails, print success! If any test does fail, halt execution and display:
	- Expected output from the dummy queue
	- Actual output from the queue
	- Previously written data to real queue
	- How many writes have occurred since the real queues were first filled
------------------------------------------------------------------------------------------------------------------------------------------------------------- */

module CircQueue_tb();

/* Define test regs and wires */
// System variables
reg clk, rst_n;
// Test status variables
reg fail, success;
// Instantiate dummy queue
reg [15:0] data [0:1020];
// Test parameters
reg [15:0] exp_out, prev_data;
reg [9:0] wrt_cnt;
// Queue ports
reg [15:0] new_smpl, wrt_smpl;
wire [15:0] smpl_out;
wire squencing;
// Necessary counters (excluding write counter)
reg [10:0] dum_cnt, t /*Test Counter*/, fail_cnt, f, h; /*Counts how many failed samples have been output*/
reg [15:0] fail_data [0:1020];
// Counter status
wire dumQ_full;
// Additional status variables
reg wrt_en; //wrt_en tells the program from the state machine to begin writing to the queues

// Define state machine variables
reg [2:0] state, nxt_state;
reg run_test; 	// specifies when the state machine should start to test the data
localparam WRT_DUM = 3'b000;
localparam TEST = 3'b001;
localparam WRT_NEW = 3'b010;
localparam OUTPUT = 3'b011;
localparam WAIT = 3'b100;
localparam RST_WRT = 3'b101;

/* Instantiate queue modules */
// Instantiate low frequency queue
LowFQueues iQ(.clk(clk),.rst_n(rst_n),.new_smpl(new_smpl),.wrt_smpl(wrt_smpl),.smpl_out(smpl_out),.sequencing(squencing));
// Instantiate high frequency queue
//HiFQueues HighFQueue1(.clk(clk),.rst_n(rst_n),.new_smpl(new_smpl),.wrt_smpl(wrt_smpl),.smpl_out(hiSmpl_out),.sequencing(hiSquencing));

initial begin
//1. Initialize all variables
clk = 1'b0; rst_n = 1'b0;
fail = 1'b0; success = 1'b0;
exp_out = 0; prev_data = 0;
wrt_cnt = 0; fail = 0;
new_smpl = 0; wrt_smpl = 1'b0;
run_test = 1'b0; 

// 2. Create a dummy queue to hold 1021 unique values that we can use to compare and measure length
for (dum_cnt = 0; dum_cnt < 1021; dum_cnt = dum_cnt + 1)
	data[dum_cnt] = dum_cnt;
	
rst_n = 1'b0;
#1020 rst_n = 1'b1;
run_test = 1'b1;
end

// Manage next state status
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= WAIT;
	else
		state <= nxt_state;
end

// Operate state machine
always @(*) begin
wrt_smpl = 1'b0;
fail_cnt = 0;
	case (state)
		WAIT : if(run_test)
			nxt_state = WRT_DUM;
		else
			nxt_state = WAIT;
		// 3. Fill the actual queues with the dummy queue vales
		WRT_DUM : if(dumQ_full) begin
				nxt_state = TEST;
			end else begin
				wrt_smpl = 1'b1;
				new_smpl = data[wrt_cnt];
				nxt_state = RST_WRT;
			end
		// 4. Test for matching data 
		TEST : begin
			if(data[t] != smpl_out) begin
				fail_cnt = fail_cnt + 1;
				fail_data[t] = smpl_out;
				fail = 1'b1;
			end
			t = t + 1;
			if(t == 1020)
				nxt_state = OUTPUT;
			else
				nxt_state = TEST;
		end
		OUTPUT : begin
			if(fail) begin
				$display("Your test was unsuccessful. The failed output samples are shown below next to the expected outputs:\n");
				$display("Expected:\t\t\tActual:");
				//Need to add an array to keep the addresses of the failed tests 
				for(h = 0; h < 1020; h = h + 1)
					if(fail_data[h] != 16'hxxxx)
						$display("%h \t\t\t %h", data[h], fail_data[h]);
			end 
				
			if(smpl_out == 2041)
				nxt_state = WAIT;
			else
				nxt_state = WRT_NEW;
		end	
		WRT_NEW : begin
			new_smpl = data[wrt_cnt];
			wrt_smpl = ~wrt_smpl;
			nxt_state = TEST;
		end
		RST_WRT : begin
			wrt_smpl = 1'b0;
			nxt_state = WRT_DUM;
			t = 0;
			for(f = 0; f < 1020; f = f + 1)
				fail_data[f] = 16'hxxxx;
		end
	endcase
end

// Instantiate the write counter - Counts how many times the actual queues have been written to. Is reset after the actual queues are filled with the dummy values
////Low Frequency queue writes every other wrt_smpl
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		wrt_en <= 1'b0;
	else if(wrt_smpl)
		wrt_en <= ~wrt_en;
	else if(wrt_cnt == 10'h3FD & ~wrt_smpl)
		wrt_en <= 1'b0;
end

always @(posedge wrt_en, negedge rst_n) begin
	if(!rst_n)
		wrt_cnt <= 10'h000;
	else if(wrt_cnt == 10'h3FD)
		wrt_cnt <= 10'h000;
	else begin
		wrt_cnt <= wrt_cnt + 1;
		data[wrt_cnt] = data[wrt_cnt] + 1021;
	end
end

//// Keep track of how many dummy samples have been written to the actual queues
assign dumQ_full = (wrt_cnt == 10'h3FD) ? 1'b1 : 1'b0;

always #1 clk = ~clk;


endmodule
