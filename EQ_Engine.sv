module EQ_Engine (
	input clk,
	input rst_n,
	input valid,
	input valid_rise,
	input valid_fall,
	input signed [15:0] lft_in,
	input signed [15:0] rht_in,
	input [11:0] LP_gain,
	input [11:0] B1_gain,
	input [11:0] B2_gain,
	input [11:0] B3_gain,
	input [11:0] HP_gain,
	input [11:0] volume,
	output sequencing,
	output signed [15:0] lft_out,
	output signed [15:0] rht_out
);

// Define outputs of the low and high pass queeues
wire [15:0] lft_LF, lft_HF, rht_LF, rht_HF;
wire LLF_seq, LHF_seq, RLF_seq, RHF_seq;	// queue sequencing status register

// Define signal outputs of the filters
wire [15:0] LP_rhtOut, LP_lftOut;	// Low pass filter outputs
wire [15:0] B1_rhtOut, B1_lftOut;	// Low Band pass filter outputs
wire [15:0] B2_rhtOut, B2_lftOut;	// Mid Band pass filter outputs
wire [15:0] B3_rhtOut, B3_lftOut;	// High Band pass filter outputs
wire [15:0] HP_rhtOut, HP_lftOut;	// High pass filter outputs

// Define scaled signal outputs from the band scaling 
wire [15:0] LLP_scaled, LB1_scaled, LB2_scaled, LB3_scaled, LHP_scaled;
wire [15:0] RLP_scaled, RB1_scaled, RB2_scaled, RB3_scaled, RHP_scaled;

// Define summed signals
reg signed [15:0] lft_sum, rht_sum;

/* Instantiate the low and high frequency queues for left signal */
LowFQueues ilft_LFQ(.clk(clk), .rst_n(rst_n), .new_smpl(lft_in), .valid_rise(valid_rise), 
					.smpl_out(lft_LF), .sequencing(LLF_seq), .valid_fall(valid_fall));
HiFQueues ilft_HFQ(.clk(clk), .rst_n(rst_n), .new_smpl(lft_in), .valid_rise(valid_rise), 
					.smpl_out(lft_HF), .sequencing(LHF_seq), .valid_fall(valid_fall));
					
/* Instantiate the low and high frequency queues for right signal */
LowFQueues irht_LFQ(.clk(clk), .rst_n(rst_n), .new_smpl(rht_in), .valid_rise(valid_rise), 
					.smpl_out(rht_LF), .sequencing(RLF_seq), .valid_fall(valid_fall));
HiFQueues irht_HFQ(.clk(clk), .rst_n(rst_n), .new_smpl(rht_in), .valid_rise(valid_rise), 
					.smpl_out(rht_HF), .sequencing(RHF_seq), .valid_fall(valid_fall));
					
/* Instantiate the filters */
LPfilt iLP(.rght_in(rht_LF), .lft_in(lft_LF), .rst_n(rst_n), .rght_out(LP_rhtOut), 
					.lft_out(LP_lftOut), .clk(clk), .sequencing(sequencing));
B1filt iB1(.rght_in(rht_LF), .lft_in(lft_LF), .rst_n(rst_n), .rght_out(B1_rhtOut), 
					.lft_out(B1_lftOut), .clk(clk), .sequencing(sequencing));
B2filt iB2(.rght_in(rht_LF), .lft_in(lft_LF), .rst_n(rst_n), .rght_out(B2_rhtOut), 
					.lft_out(B2_lftOut), .clk(clk), .sequencing(sequencing));
B3filt iB3(.rght_in(rht_HF), .lft_in(lft_HF), .rst_n(rst_n), .rght_out(B3_rhtOut), 
					.lft_out(B3_lftOut), .clk(clk), .sequencing(sequencing));
HPfilt iHP(.rght_in(rht_HF), .lft_in(lft_HF), .rst_n(rst_n), .rght_out(HP_rhtOut), 
					.lft_out(HP_lftOut), .clk(clk), .sequencing(sequencing));
					
/* Instantiate the Band Scaling */
// Left signals
bandScale iLLP(.clk(clk), .POT(LP_gain), .audio(LP_lftOut), .scaled(LLP_scaled));
bandScale iLB1(.clk(clk), .POT(B1_gain), .audio(B1_lftOut), .scaled(LB1_scaled));
bandScale iLB2(.clk(clk), .POT(B2_gain), .audio(B2_lftOut), .scaled(LB2_scaled));
bandScale iLB3(.clk(clk), .POT(B3_gain), .audio(B3_lftOut), .scaled(LB3_scaled));
bandScale iLHP(.clk(clk), .POT(HP_gain), .audio(HP_lftOut), .scaled(LHP_scaled));

// Right signals
bandScale iRLP(.clk(clk), .POT(LP_gain), .audio(LP_rhtOut), .scaled(RLP_scaled));
bandScale iRB1(.clk(clk), .POT(B1_gain), .audio(B1_rhtOut), .scaled(RB1_scaled));
bandScale iRB2(.clk(clk), .POT(B2_gain), .audio(B2_rhtOut), .scaled(RB2_scaled));
bandScale iRB3(.clk(clk), .POT(B3_gain), .audio(B3_rhtOut), .scaled(RB3_scaled));
bandScale iRHP(.clk(clk), .POT(HP_gain), .audio(HP_rhtOut), .scaled(RHP_scaled));

/* Sum scaled signals */
// Left Signals
assign lft_sum = LLP_scaled + LB1_scaled + LB2_scaled + LB3_scaled + LHP_scaled;

// Right Signals
assign rht_sum = RLP_scaled + RB1_scaled + RB2_scaled + RB3_scaled + RHP_scaled;

/* Scale by volume */
assign lft_out = volume * lft_sum;
assign rht_out = volume * rht_sum;

/* sequencing output logic */
assign sequencing = (LLF_seq & LHF_seq & RLF_seq & RHF_seq);


endmodule
