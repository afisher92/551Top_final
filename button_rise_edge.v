
module button_rise_edge(clk, next_chnnl, rst_n, button_rise_edge);

input rst_n, next_chnnl, clk;
output button_rise_edge;

reg FF1, FF2, FF3;

always @(posedge clk) begin
  if(!rst_n) begin
   FF1 <= 1'b1;
   FF2 <= 1'b1;
   FF3 <= 1'b1;
  end else begin
   FF1 <= next_chnnl;
   FF2 <= FF1;
   FF3 <= FF2;
  end
end //end always

assign button_rise_edge = ~FF3 & FF2;

endmodule
