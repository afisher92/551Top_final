module LED (
	input clk,
	input rst_n,
	input [15:0] rht_out,
	input [15:0] lft_out,
	output reg [7:0] LED
);

reg [31:0] cnt;

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cnt <= 32'h0000000;
	else if(cnt == 32'h04000000)
		cnt <= 32'h00000000;
	else
		cnt <= cnt + 1;
end

always @(posedge cnt[25], negedge rst_n) begin
	if(!rst_n)
		LED[3:0] <= 4'h0;
	else if(~&rht_out[15:4])
		LED[3:0] <= 4'b1100;
	else if(~&rht_out[15:8])
		LED[3:0] <= 4'b1110;
	else if(~&rht_out[15:12])
		LED[3:0] <= 4'b1111;
	else
		LED[3:0] <= 4'b1000;
end

always @(posedge cnt[25], negedge rst_n) begin
	if(!rst_n)
		LED[7:4] <= 4'h0;
	else if(~&lft_out[15:4])
		LED[7:4] <= 4'b0011;
	else if(~&lft_out[15:8])
		LED[7:4] <= 4'b0111;
	else if(~&lft_out[15:12])
		LED[7:4] <= 4'b1111;
	else
		LED[7:4] <= 4'b0001;
end

endmodule