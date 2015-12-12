
module A2D_intf(clk, rst_n, chnnl, strt_cnv, MISO, cnv_cmplt, res, A2D_SS_n, SCLK, MOSI);

input clk, rst_n, MISO, strt_cnv;
input [2:0]chnnl;

output A2D_SS_n, MOSI, SCLK;
output [11:0] res;
output cnv_cmplt;

reg [2:0]state, nxtstate;
reg set_cc, wrt, cnv_cmplt;
reg [11:0] res;

reg [15:0] rd_data, cmd;

wire done;

localparam IDLE = 2'b00;
localparam WAIT = 2'b01;
localparam SPI_snd = 2'b10;
localparam SPI_get = 2'b11;

SPI_mstr iSPI(.clk(clk), .rst_n(rst_n), .SS_n(A2D_SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .wrt(wrt), .done(done), .rd_data(rd_data), .cmd(cmd));

//Implement next state
always @(posedge clk, negedge rst_n) begin
 if(!rst_n)
  state <= IDLE;
 else
  state <= nxtstate;
end

//Implement cnv_cmplt
always @(posedge clk, negedge rst_n) begin
 if(!rst_n)
  cnv_cmplt <= 1'b0;
 else if(strt_cnv)
  cnv_cmplt <= 1'b0;
 else if(set_cc)
  cnv_cmplt <= 1'b1;
end

//Implement State Machine
always @(*) begin
  wrt = 0;
  set_cc = 0;
  nxtstate = IDLE;
  case(state)
	IDLE : if(strt_cnv) begin
		nxtstate = SPI_snd;
		wrt = 1;
	end else 
		nxtstate = IDLE;
	SPI_snd : if(!done) 
		nxtstate = SPI_snd;
	else
		nxtstate = WAIT;
	WAIT : begin
		nxtstate = SPI_get;
		wrt = 1;
	end 
	SPI_get : if(!done)
		nxtstate = SPI_get;
	else begin
	   set_cc = 1;
		nxtstate = IDLE;
	end
	default : nxtstate = IDLE;
  endcase
end //end always

assign cmd = {2'b00, chnnl, 11'h000};
assign res = rd_data[11:0];

endmodule
