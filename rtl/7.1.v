/*
 * reference: ../src/7.1.c
 * fsm1: exchange
 * fsm2: partition
 * fsm3: quicksort
 * fsm: main
 */

module quicksort #(
	parameter A_D_MSB = 7, 
	parameter A_P_MSB = 3
)(
	output reg [1:0] cst1, nst1, 
	output reg [3:0] cst2, nst2, 
	output reg [3:0] cst3, nst3, 
	output reg [2:0] cst, nst, 
	output full, empty, idle, 
	input push, pop, clear, sort, 
	output reg [A_D_MSB:0] tx_data, 
	input [A_D_MSB:0] rx_data, 
	input enable, 
`ifdef ASYNC
	input rstn, clk, async_se, lck, lck1, lck2, lck3, test_se 
`else
	input rstn, clk 
`endif
);

`ifdef ASYNC
wire clk1 = test_se ? clk : async_se ? lck1 : clk;
wire clk2 = test_se ? clk : async_se ? lck2 : clk;
wire clk3 = test_se ? clk : async_se ? lck3 : clk;
wire clk0 = test_se ? clk : async_se ? lck  : clk;
wire clk10 = clk1 | clk0;
`endif

parameter A_A_MSB = ((2**A_P_MSB)-1);

reg [A_D_MSB:0] A[0:((2**(A_A_MSB+1))-1)];
reg [A_A_MSB:0] a_top;
assign empty = a_top == 0;
assign full = a_top == {(A_A_MSB+1){1'b1}};
reg [A_A_MSB:0] i, j;
wire [A_D_MSB:0] A_i = A[i];
wire [A_D_MSB:0] A_j = A[j];
reg [A_D_MSB:0] e, x;
reg [(A_A_MSB+1)+(A_A_MSB+1)-1:0] pr[0:((2**(A_P_MSB+1))-1)];
reg [A_P_MSB:0] pr_top;
wire empty_pr = pr_top == 0;
reg [A_A_MSB:0] p, r, q;

wire [(A_A_MSB+1)+(A_A_MSB+1)-1:0] top_pr = pr[pr_top];
wire [A_P_MSB:0] pr_top_left = pr_top - 1;
wire [A_P_MSB:0] pr_top_right = pr_top + 1;
wire [A_A_MSB:0] a_top_left = a_top - 1;
wire [A_A_MSB:0] a_top_right = a_top + 1;

`ifndef GRAY
	`define GRAY(X) (X^(X>>1))
`endif

reg req1;
reg req2;
reg req3;

localparam [1:0]
	st1_j		= `GRAY(2),
	st1_i		= `GRAY(1),
	st1_idle	= `GRAY(0);
wire ack1 = cst1 == st1_idle;
reg req1_d;
`ifdef ASYNC
always@(negedge rstn or posedge clk1) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req1_d <= 1'b0;
	else if(enable) req1_d <= req1;
end
wire req1_x = req1_d ^ req1;
`ifdef ASYNC
always@(negedge rstn or posedge clk1) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) cst1 <= st1_idle;
	else if(enable) cst1 <= nst1;
	else cst1 <= st1_idle;
end
always@(*) begin
	case(cst1)
		st1_idle: nst1 = req1_x ? st1_i : cst1;
		st1_i: nst1 = st1_j;
		st1_j: nst1 = st1_idle;
		default: nst1 = st1_idle;
	endcase
end

localparam [3:0]
	st2_4		= `GRAY(9),
	st2_1		= `GRAY(8),
	st2_j		= `GRAY(7),
	st2_i		= `GRAY(6),
	st2_3		= `GRAY(5),
	st2_2		= `GRAY(4),
	st2_if		= `GRAY(3),
	st2_for		= `GRAY(2),
	st2_x		= `GRAY(1),
	st2_idle	= `GRAY(0);
wire ack2 = cst2 == st2_idle;
reg req2_d;
`ifdef ASYNC
always@(negedge rstn or posedge clk2) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req2_d <= 1'b0;
	else if(enable) req2_d <= req2;
end
wire req2_x = req2_d ^ req2;
`ifdef ASYNC
always@(negedge rstn or posedge clk2) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) cst2 <= st2_idle;
	else if(enable) cst2 <= nst2;
	else cst2 <= st2_idle;
end
wire for_check = j != r;
wire if_exch = A_j < x;
always@(*) begin
	case(cst2)
		st2_idle: nst2 = req2_x ? st2_x : cst2;
		st2_x: nst2 = st2_for;
		st2_for: nst2 = for_check ? st2_if : st2_1;
		st2_if: nst2 = if_exch ? st2_2 : st2_j;
		st2_2: nst2 = st2_3;
		st2_3: nst2 = ack1 ? st2_i : cst2;
		st2_i: nst2 = st2_j;
		st2_j: nst2 = st2_for;
		st2_1: nst2 = st2_4;
		st2_4: nst2 = ack1 ? st2_idle : cst2;
		default: nst2 = st2_idle;
	endcase
end
`ifdef ASYNC
always@(negedge rstn or posedge clk2) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req1 <= 1'b0;
	else if(enable) begin
		case(nst2)
			st2_2: req1 <= ~req1;
			st2_1: req1 <= ~req1;
			default: req1 <= req1;
		endcase
	end
end

localparam [3:0]
	st3_pushp	= `GRAY(8),
	st3_ifr		= `GRAY(7),
	st3_pushr	= `GRAY(6),
	st3_ifp		= `GRAY(5),
	st3_1		= `GRAY(4),
	st3_pop		= `GRAY(3),
	st3_while	= `GRAY(2),
	st3_push	= `GRAY(1),
	st3_idle	= `GRAY(0);
wire ack3 = cst3 == st3_idle;
reg req3_d;
`ifdef ASYNC
always@(negedge rstn or posedge clk3) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req3_d <= 1'b0;
	else if(enable) req3_d <= req3;
end
wire req3_x = req3_d ^ req3;
`ifdef ASYNC
always@(negedge rstn or posedge clk3) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) cst3 <= st3_idle;
	else if(enable) cst3 <= nst3;
	else cst3 <= st3_idle;
end
wire [A_A_MSB:0] q_left = q - 1;
wire [A_A_MSB:0] q_right = q + 1;
wire if_p = (q_left > p);
wire if_r = (q_right < r);
always@(*) begin
	case(cst3)
		st3_idle: nst3 = req3_x ? st3_push : cst3;
		st3_push: nst3 = st3_while;
		st3_while: nst3 = empty_pr ? st3_idle : st3_pop;
		st3_pop: nst3 = st3_1;
		st3_1: nst3 = ack2 ? st3_ifp : cst3;
		st3_ifp: nst3 = if_p ? st3_pushr : st3_ifr;
		st3_pushr: nst3 = st3_ifr;
		st3_ifr: nst3 = if_r ? st3_pushp : st3_while;
		st3_pushp: nst3 = st3_while;
		default: nst3 = st3_idle;
	endcase
end
`ifdef ASYNC
always@(negedge rstn or posedge clk3) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req2 <= 1'b0;
	else if(enable) begin
		case(nst3)
			st3_pop: req2 <= ~req2;
			default: req2 <= req2;
		endcase
	end
end

localparam [2:0]
	st_1		= `GRAY(5),
	st_sort		= `GRAY(4),
	st_pop		= `GRAY(3),
	st_push		= `GRAY(2),
	st_clear	= `GRAY(1),
	st_idle		= `GRAY(0);
reg clear_d, push_d, pop_d, sort_d;
`ifdef ASYNC
always@(negedge rstn or posedge clk0) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) begin
		clear_d <= 1'b0;
		push_d <= 1'b0;
		pop_d <= 1'b0;
		sort_d <= 1'b0;
	end
	else if(enable) begin
		clear_d <= clear;
		push_d <= push;
		pop_d <= pop;
		sort_d <= sort;
	end
end
wire clear_x = clear_d ^ clear;
wire push_x = push_d ^ push;
wire pop_x = pop_d ^ pop;
wire sort_x = sort_d ^ sort;
`ifdef ASYNC
always@(negedge rstn or posedge clk0) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) cst <= st_idle;
	else if(enable) cst <= nst;
	else cst <= st_idle;
end
always@(*) begin
	case(cst)
		st_idle: nst = clear_x ? st_clear : push_x ? st_push : pop_x ? st_pop : sort_x ? st_sort : cst;
		st_clear: nst = st_idle;
		st_push: nst = st_idle;
		st_pop: nst = st_idle;
		st_sort: nst = st_1;
		st_1: nst = ack3 ? st_idle : cst;
		default: nst = st_idle;
	endcase
end
`ifdef ASYNC
always@(negedge rstn or posedge clk0) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) req3 <= 1'b0;
	else if(enable) begin
		case(nst)
			st_sort: req3 <= ~req3;
			default: req3 <= req3;
		endcase
	end
end
assign idle = cst == st_idle;

`ifdef ASYNC
always@(negedge rstn or posedge clk2) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) begin
		i <= 0;
		j <= 0;
		x <= 0;
		q <= 0;
	end
	else if(enable) begin
		case(nst2)
			st2_x: begin
				x <= A[r];
				i <= p;
				j <= p;
			end
			st2_j: j <= j + 1;
			st2_i: i <= i + 1;
			st2_idle: q <= i;
			default: begin
				i <= i;
				j <= j;
				x <= x;
				q <= q;
			end
		endcase
	end
end

`ifdef ASYNC
always@(negedge rstn or posedge clk3) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) begin
		pr_top <= 0;
		p <= 0;
		r <= 0;
	end
	else if(enable) begin
		case(nst3)
			st3_push: begin
				pr[pr_top_right] <= {{{((A_A_MSB+1)-1){1'b0}},1'b1}, a_top};
				pr_top <= pr_top_right;
			end
			st3_pop: begin
				p <= top_pr[(A_A_MSB+1)+(A_A_MSB+1)-1:(A_A_MSB+1)];
				r <= top_pr[A_A_MSB:0];
				pr_top <= pr_top_left;
			end
			st3_pushr: begin
				pr[pr_top_right] <= {p, q_left};
				pr_top <= pr_top_right;
			end
			st3_pushp: begin
				pr[pr_top_right] <= {q_right, r};
				pr_top <= pr_top_right;
			end
			default: begin
				pr_top <= pr_top;
				p <= p;
				r <= r;
			end
		endcase
	end
end

`ifdef ASYNC
always@(negedge rstn or posedge clk10) begin
`else
always@(negedge rstn or posedge clk) begin
`endif
	if(!rstn) begin
		e <= 0;
		a_top <= 0;
		tx_data <= 0;
	end
	else if(enable) begin
		case(nst1)
			st1_i: begin 
				e <= A_i;
				A[i] <= A_j; 
			end
			st1_j: A[j] <= e;
			default: e <= e;
		endcase
		case(nst)
			st_clear: a_top <= 0;
			st_push: begin
				A[a_top_right] <= rx_data;
				a_top <= a_top_right;
			end
			st_pop: begin
				tx_data <= A[a_top];
				a_top <= a_top_left;
			end
			default: begin
				a_top <= a_top;
				tx_data <= tx_data;
			end
		endcase
	end
end

endmodule
