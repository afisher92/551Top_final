module reset_synch(RST_n, clk, rst_n);

input RST_n, clk;
output rst_n;
reg rst_n, FF1;

always @(negedge clk, negedge RST_n) begin
	if(!RST_n) begin
		FF1 <= 1'b0;
		rst_n <= FF1; 
	end
	else begin
		FF1 <= 1'b1;
		rst_n <= FF1;
	end
end

endmodule
