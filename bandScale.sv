module bandScale(clk, POT, audio, scaled);

input [11:0] POT;
input clk;
input signed [15:0] audio;
output signed [15:0] scaled;

wire [23:0] UnsignedMult = POT*POT;
wire [12:0] signedInput = {1'b0,UnsignedMult[23:12]};
wire signed [28:0] SignedMult = signedInput * audio;
wire signed [3:0]  sat = SignedMult[28:25];
wire signed [15:0] finalAudio = SignedMult[25:10];
wire signed sat_neg, sat_pos;

assign sat_neg = SignedMult[28] & ~&SignedMult[27:25];
assign sat_pos = ~SignedMult[28] & |SignedMult[27:25];

assign scaled = (sat_pos)  ?   16'h8000 :
		(sat_neg)  ?   16'h7fff :
		finalAudio;

endmodule
