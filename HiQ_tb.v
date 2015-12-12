module newHi_tb();

reg clk, rst_n, wrt_smpl;
reg [15:0] data [0:1536];
reg [15:0] new_smpl;
wire [15:0] smpl_out;
wire sequencing;

// Counters
reg [10:0] dumCnt, wrtCnt;

reg [2:0] state, nxt_state, curr;
reg run_test;
localparam WAIT = 3'b000;
localparam WRT_DUM = 3'b001;
localparam WRT_NEW = 3'b010;
localparam RST_WRT = 3'b011;

HiFQueues iQ(.clk(clk),.rst_n(rst_n),.new_smpl(new_smpl),.wrt_smpl(wrt_smpl),.smpl_out(smpl_out),.sequencing(sequencing));

initial begin
clk = 1'b0;
run_test = 1'b0;
new_smpl = 16'h0000; 
wrt_smpl = 1'b0;
wrtCnt = 11'h000;

for(dumCnt = 0; dumCnt < 1531; dumCnt = dumCnt + 1) 
	data[dumCnt] = dumCnt;

rst_n = 1'b0;	
#10 rst_n = 1'b1;
run_test = 1'b1;
	
end

always @(*) begin
	case(state)
		WAIT : begin
			curr = WAIT;
			if(run_test)
				nxt_state = WRT_DUM;
			else 
				nxt_state = WAIT;
		end
		WRT_DUM : begin
			curr = WRT_DUM;
			if(wrtCnt == 1531)
				nxt_state = WRT_NEW;
			else begin
				nxt_state = RST_WRT;
				wrt_smpl = 1'b1;
				new_smpl = data[wrtCnt];
			end
		end
		WRT_NEW : begin
			curr = WRT_NEW;
			new_smpl = data[wrtCnt];
			wrt_smpl = 1'b1;
			if(smpl_out >= 3070)
				nxt_state = WAIT;
			else
				nxt_state = RST_WRT;
		end
		RST_WRT : begin
			nxt_state = curr;
			wrt_smpl = 1'b0;
		end
	endcase	
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= WAIT;
	else
		state <= nxt_state;
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		wrtCnt <= 11'h000;
	else if(wrtCnt == 1531)
		wrtCnt <= 11'h000;
	else if(wrt_smpl) begin
		wrtCnt <= wrtCnt + 1;
		data[wrtCnt] <= data[wrtCnt] + 1;
	end
end

always #1 clk = ~clk;

endmodule
