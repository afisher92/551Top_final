`timescale 1ns/1ps
module Equalizer_tb();
  ////////////////////////////
  // Shell of a test bench //
  //////////////////////////

  reg clk,RST_n, rst_n, LRCLK;
  
  wire [7:0] LEDS;
  wire [2:0] chnnl;
  reg signed [15:0] aout_lft,aout_rht;
  integer lft_max, j, lft_min, rht_max, rht_min, rht_crossing, lft_crossing, lft_blanking, rht_blanking, lft_avg, rht_avg, i, file, rsum, lsum;
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                 .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.MCLK(MCLK),.SCL(SCLK),.LRCLK(LRCLK),
				 .SDout(SDout),.SDin(SDin),.AMP_ON(AMP_ON),.RSTn(RSTn));
				 
  //////////////////////////////////////////
  // Instantiate model of CODEC (CS4271) //
  ////////////////////////////////////////
  CS4272  iModel( .MCLK(MCLK), .SCLK(SCLK), .LRCLK(LRCLK),
                .RSTn(RSTn),  .SDout(SDout), .SDin(SDin),
                .aout_lft(aout_lft), .aout_rht(aout_rht));
				
  ///////////////////////////////////////////////////////////////////////
  // Instantiate Model of A2D converter modeling slide potentiometers //
  /////////////////////////////////////////////////////////////////////
  ADC128S iA2D(.clk(clk),.rst_n(rst_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
               .MISO(A2D_MISO),.MOSI(A2D_MOSI));
				
  initial begin
  clk = 0;
  i = 0;
  j = 0;

  RST_n = 0;
  rst_n = 0;
  lft_max = 0;
  lft_min = 3000;
  rht_max = 0;
  rht_min = 3000;
  rht_crossing = 0;
  lft_crossing = 0;
  lft_blanking = 0;
  rht_blanking = 0;
  lsum = 0;
  rsum = 0;
  lft_avg = 0;
  rht_avg = 0;
  @(posedge clk)
  @(negedge clk)
  RST_n = 1;
  rst_n = 1;
  #5;
  file = $fopen("results.csv");
end  

 //write the audio out to the file 
always@(posedge LRCLK) begin
if(aout_rht != 0 || aout_lft != 0)begin
  $fdisplay (file,"%d,%d", aout_rht, aout_lft);
  j = j+1;
 end
end
  
 //check the max and min of the left and right channels
  always@(posedge clk) begin
    if (aout_rht > rht_max)
      rht_max = aout_rht;
    if (aout_lft > lft_max)
      lft_max = aout_lft;
    if (aout_rht < rht_min)
      rht_min = aout_rht;
    if (aout_lft < lft_max)
      lft_min = aout_lft;      
  end
  
  //check for the crossings
  always@(posedge clk) begin
    if(aout_rht == 0)
     rht_crossing = rht_crossing+1;
    if(aout_lft == 0)
     lft_crossing = lft_crossing+1;  
  end
  
  always@(posedge clk) begin
   i = i+1;
   rsum = rsum + aout_rht;
   lsum = lsum + aout_lft;
   lft_avg = lsum/i;
   rht_avg = rsum/i;
  end

  always
    #1 clk = ~clk;

endmodule