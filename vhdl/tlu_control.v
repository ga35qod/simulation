`timescale 1ns / 1ps


module tlu_control(
	input clk,
    input rst,
    input [5:0] clk_slow_down_factor,
    input [31:0] timeout_factor,
    input [31:0] tn2a_default,
	input [31:0] trg_cnt_default,
	//tlu
	input tlu_reset,
    input tlu_trigger,
    output  wire tlu_trigger_clk,
    output  reg tlu_busy,
    // to trigger unit
    output ts_2tu,

	//to aurora receiver
    output reg ts_2a,
    output reg [31:0]tn2a
	);
	

//parameter clk_slow_down_factor = 3;

localparam IDLE 		= 	0;
localparam READY_TO_GET	=	1;
localparam GETTING_TRG	=	2;
localparam SND_TRG2AU	=	3;
localparam SND_TRG2TL	=	4;
localparam WAIT0 = 5;
localparam WAIT1 = 6;
localparam WAIT2 = 7;
localparam WAIT3 = 8;
localparam WAIT4 = 9;
localparam WAIT5 = 10;
//parameter DONE			=	5;


reg [15:0] 	trg_num; 
reg [4:0]	state, state_del;
wire state_change_strobe,timeout;
reg [31:0]	cnt_timeout;
reg [7:0]   num_trg_bits;
reg [2**5-1:0] tlu_clk_cnt;
reg tlu_trigger_clk_dly;
wire tlu_trigger_clk_neg_stobe;
wire [7:0] max_bits;
wire [15:0] ts_2tu_del;


//delay and number of bits parameters
assign max_bits 	= 	trg_cnt_default[7:0];
assign ts_2tu_del	=	trg_cnt_default[23:8];
//assign ts_2a_del	=	trg_cnt_default[23:16];


reg [31:0] cnt_wait;
//assign ts_2a	=	(state==GETTING_TRG)&&(cnt_wait==ts_2tu_del);
assign ts_2tu 	= 	(state==GETTING_TRG)&&(cnt_wait==ts_2tu_del);
assign rst_int 	= 	rst || tlu_reset;

always @(posedge clk)
if (rst_int ) begin
	trg_num 		<= 	0;
	state			<=	IDLE;
	tlu_busy		<=	0;
	tn2a			<=	tn2a_default;
	num_trg_bits	<=	0;
	cnt_wait		<=	0;
	
end else begin
	case (state)
		IDLE: 	begin
			tlu_busy <= 0;
			cnt_wait <= cnt_wait+1;
			ts_2a <= 0;
			//wait a little
			if (cnt_wait > (1<<clk_slow_down_factor))
				if (tlu_trigger) begin
					trg_num <= 0;
					state <= READY_TO_GET;
					cnt_wait <= 0;
				end
		end  
		WAIT0: begin
			cnt_wait <= cnt_wait + 1;
			if(cnt_wait == 20) begin
				state <= READY_TO_GET;
				cnt_wait <= 0;
			end
		end
		READY_TO_GET: begin
				tlu_busy <= 1;
				if (!tlu_trigger ||timeout) begin
					state <= GETTING_TRG;
				end
		end
		GETTING_TRG: if ((num_trg_bits < max_bits) && (!timeout)) begin
				cnt_wait <= cnt_wait+1;
				if (tlu_trigger_clk_neg_stobe) begin
					num_trg_bits <= num_trg_bits + 1;
//					trg_num <= {tlu_trigger, trg_num[31:1]};
					trg_num <= {tlu_trigger, trg_num[15:1]};
				end
		end else begin
				num_trg_bits <= 0;
				state <= IDLE;
				tn2a[15:0] <= trg_num;
				tn2a[31:16] <= 'h0;
				cnt_wait <= 0;
				ts_2a <= 1;
//				trg_num			<= 32'b0;
		end
		default:state <= IDLE;
	endcase 
end


//timeout


assign timeout = cnt_timeout > (timeout_factor << clk_slow_down_factor);
assign state_change_strobe = (state!=state_del);
always @(posedge clk) 
if (rst)begin
	cnt_timeout <= 0;
	state_del <= IDLE;
end else begin
	state_del <= state;
	if (state_change_strobe)
		cnt_timeout <= 0;
	else if (!(state!=IDLE || state != WAIT0))
		cnt_timeout <= cnt_timeout+1;

	if (cnt_timeout == (timeout_factor << clk_slow_down_factor))
		$display("timeout reached!!!!!!!!!!!!!!!!!!!!!!!!!!");
end







assign tlu_trigger_clk = tlu_clk_cnt[clk_slow_down_factor]&&(state==GETTING_TRG);

always @ (posedge clk)
if (rst_int) begin
	tlu_clk_cnt <= 0;
end else begin
	if (state != READY_TO_GET) 
		tlu_clk_cnt <= tlu_clk_cnt + 1;
	else
		tlu_clk_cnt <= 0;
end




always @(posedge clk)
	tlu_trigger_clk_dly <= tlu_trigger_clk;

assign tlu_trigger_clk_neg_stobe = tlu_trigger_clk_dly&&(!tlu_trigger_clk);

endmodule
