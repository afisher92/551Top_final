module codec_intf_tb();

reg clk, rst_n;
wire LRCLK, SCLK, MCLK, RSTn, SDout, SDin;

codec_intf iINTF(.lft_in(lft_in), .rht_in(rht_in), .valid(valid), .lft_out(lft_out), .rht_out(rht_out), .LRCLK(LRCLK), .SCLK(SCLK), .MCLK(MCLK), .RSTn(RSTn), .clk(clk), .rst_n(rst_n), .SDin(SDin), .SDout(SDout));

CS4272 iCODEC(.MCLK(MCLK), .RSTn(RSTn), .SCLK(SCLK), .LRCLK(LRCLK), .SDout(SDout), .SDin(SDin), .aout_lft(aout_lft), .aout_rht(aout_rht));

initial begin
  clk = 0;
  rst_n = 0;
  #40@(posedge clk) rst_n = 1;
end

always begin
	#20 clk = ~clk;
end


endmodule