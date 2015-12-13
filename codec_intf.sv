module codec_intf(lft_in, rht_in, valid, lft_out, rht_out, LRCLK, SCLK, MCLK, RSTn, clk, rst_n, SDin, SDout, set_valid, LRCLK_rise);

input clk, rst_n, SDout;
input signed [15:0] lft_out, rht_out;

output reg signed [15:0] lft_in, rht_in;
output reg valid;
output LRCLK, SCLK, MCLK, RSTn, SDin;
output LRCLK_rise, set_valid;

//Designate any registers or wires//
reg signed [15:0] inshift_reg; 								 //Input buffer, Manage SDIN from CODEC and lft/rht_in
reg [15:0] outshift_reg, lft_buffin, rht_buffin; 		 //Output double buffer. Manage SDOUT to CODEC and lft/rht_out
reg [10:0] cnt;											 //Counter that iterates with clk
reg LRCLK, SCLK, MCLK, RSTn;							 //Control clocks

reg set_valid, LRCLK_fall, LRCLK_rise; 		//Valid control and edge detection signals
reg SCLK_fall, SCLK_rise;					//SCLK edge detection
//End register and wire designation//

/*-- Implement Input Buffers From Digital Core --*/
always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		rht_buffin <= 16'h0000;
		lft_buffin <= 16'h0000;
	end
	else if (set_valid) begin
		rht_buffin <= rht_out;
		lft_buffin <= lft_out;
	end
end

/*-- Implement Valid --*/
assign set_valid = ~LRCLK & &cnt[8:5] & SCLK_rise & RSTn;
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		valid <= 1'b0;
	else if(set_valid)
		valid <= 1'b1;
	else if(LRCLK_rise)
		valid <= 1'b0;
end

/*--Implement Output Shift Register (TO codec) -*/
always @(negedge clk, negedge rst_n) begin
  if(!rst_n)
	outshift_reg <= 16'h0000;
  else if(LRCLK_rise)
	outshift_reg <= lft_buffin;		//Load 16-bit data from left channel
  else if(LRCLK_fall)
	outshift_reg <= rht_buffin;		//Same as above. Opposite channel. 
  else if(SCLK_fall)
	outshift_reg <= {outshift_reg[14:0], outshift_reg[15]};		//Rotates signal. The full 16 bits change every 16 SCLKs 
end

assign SDin = outshift_reg[15];		//Serial data TO CODEC

/*-- Implement Input Shift Register (FROM codec) --*/
always @(posedge clk, negedge rst_n) begin
  if(!rst_n) 
	inshift_reg <= 16'h0000;
  else if(SCLK_rise)
	inshift_reg <= {inshift_reg[14:0], SDout};
end

/*-- Instantiate Out Signals to Digital Core --*/
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		lft_in <= 16'h0000;
	else if(LRCLK_fall)
		lft_in <= inshift_reg;
end

always @(posedge clk) begin
	if(LRCLK_rise)
		rht_in <= inshift_reg;
end
//Don't need buffers since parallel data only needs to be valid while valid is asserted

/*-- Implement master counter --*/
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    cnt <= 11'h200;
  else if(&cnt)
    cnt <= 11'h400;		//Reset counter to cnt[10] = 1 to maintain RSTn
  else
    cnt <= cnt + 1;
end

assign LRCLK = cnt[9];		//Instantiate LRCLK - 48.828kHz
assign SCLK = cnt[4];		//Instantiate SCLK - 1.5625MHz
assign MCLK = cnt[1];		//Instantiate MCLK - 12.5MHz
assign RSTn = cnt[10];		//Instantiate RSTn

assign LRCLK_rise 	= (~cnt[9] && &cnt[8:0]) ? 1'b1 : 1'b0;
assign LRCLK_fall 	= &cnt[9:0] ? 1'b1 : 1'b0;
assign SCLK_rise	= (~cnt[4] && &cnt[3:0]) ? 1'b1 : 1'b0;
assign SCLK_fall	= &cnt[4:0] ? 1'b1 : 1'b0;

/*-- END counter and clock designations --*/

endmodule