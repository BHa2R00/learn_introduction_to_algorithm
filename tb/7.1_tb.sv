//`define ASYNC
`include "../rtl/7.1.v"
`timescale 1ns/100ps

module quicksort_tb;

parameter A_D_MSB = 7;
parameter A_P_MSB = 3;

reg rstn, enable;
reg clk;
initial clk = 1'b0;
always #4.446 clk = ~clk;
reg [A_D_MSB:0] rx_data;
wire [A_D_MSB:0] tx_data;
reg push, pop, clear, sort;
wire full, empty, idle;
wire [1:0] cst1, nst1;
wire [3:0] cst2, nst2;
wire [3:0] cst3, nst3;
wire [2:0] cst, nst;

`ifndef GRAY
	`define GRAY(X) (X^(X>>1))
`endif

localparam [1:0]
	st1_j		= `GRAY(2),
	st1_i		= `GRAY(1),
	st1_idle	= `GRAY(0);

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

localparam [2:0]
	st_1		= `GRAY(5),
	st_sort		= `GRAY(4),
	st_pop		= `GRAY(3),
	st_push		= `GRAY(2),
	st_clear	= `GRAY(1),
	st_idle		= `GRAY(0);

reg [127:0] test_phase, test_phase1, test_phase2, test_phase3;
always@(posedge clk) begin
	case(nst1)
		st1_idle: test_phase1 = "nst1_idle";
		st1_i: test_phase1 = "nst1_i";
		st1_j: test_phase1 = "nst1_j";
	endcase
	case(nst2)
		st2_idle: test_phase2 = "nst2_idle";
		st2_x: test_phase2 = "nst2_x";
		st2_for: test_phase2 = "nst2_for";
		st2_if: test_phase2 = "nst2_if";
		st2_2: test_phase2 = "nst2_2";
		st2_3: test_phase2 = "nst2_3";
		st2_i: test_phase2 = "nst2_i";
		st2_j: test_phase2 = "nst2_j";
		st2_1: test_phase2 = "nst2_1";
		st2_4: test_phase2 = "nst2_4";
	endcase
	case(nst3)
		st3_idle: test_phase3 = "nst3_idle";
		st3_push: test_phase3 = "nst3_push";
		st3_while: test_phase3 = "nst3_while";
		st3_pop: test_phase3 = "nst3_pop";
		st3_1: test_phase3 = "nst3_1";
		st3_ifp: test_phase3 = "nst3_ifp";
		st3_pushr: test_phase3 = "nst3_pushr";
		st3_ifr: test_phase3 = "nst3_ifr";
		st3_pushp: test_phase3 = "nst3_pushp";
	endcase
	case(nst)
		st_idle: test_phase = "nst_idle";
		st_clear: test_phase = "nst_clear";
		st_push: test_phase = "nst_push";
		st_pop: test_phase = "nst_pop";
		st_sort: test_phase = "nst_sort";
		st_1: test_phase = "nst_1";
	endcase
end

quicksort #(
	.A_D_MSB(A_D_MSB), 
	.A_P_MSB(A_P_MSB)
) dut(
`ifdef ASYNC
	.async_se(1'b1), 
	.test_mode(1'b0), 
`endif
	//.test_se(1'b0), 
	.cst1(cst1), .nst1(nst1), 
	.cst2(cst2), .nst2(nst2), 
	.cst3(cst3), .nst3(nst3), 
	.cst(cst), .nst(nst), 
	.full(full), .empty(empty), .idle(idle), 
	.push(push), .pop(pop), .clear(clear), .sort(sort), 
	.tx_data(tx_data), 
	.rx_data(rx_data), 
	.enable(enable), 
	.rstn(rstn), .clk(clk)
);

task push_and_pop;
	begin
		$write("\n");
		repeat(2) @(negedge clk); clear = ~clear;
		$write("push\n");
		repeat($urandom_range(100, ((2**(A_P_MSB+1))-2))) begin
			rx_data = $urandom_range(0, ((2**(A_D_MSB+1))-1));
			$write("%d ", rx_data);
			repeat(10) @(negedge clk);
			push = ~push;
			repeat(2) @(negedge clk);
		end
		$write("\n");
		repeat(2) @(negedge clk); sort = ~sort;
		$write("pop\n");
		@(posedge idle);
		while(!empty) begin
			repeat(10) @(negedge clk);
			if(idle) begin
				$write("%d ", tx_data);
				pop = ~pop;
			end
			repeat(2) @(negedge clk);
		end
		$write("\n");
		repeat(10000) @(negedge clk);
	end
endtask

initial begin
	{rstn, enable, push, pop, clear, sort} = 0;
	rx_data = $urandom_range(0, ((2**(A_D_MSB+1))-1));
	repeat(2) @(negedge clk); rstn = 1'b1;
	repeat(2) @(negedge clk); enable = 1'b1;
	repeat(10) push_and_pop();
	repeat(2) @(negedge clk); enable = 1'b0;
	repeat(2) @(negedge clk); rstn = 1'b0;
	$finish;
end

initial begin
	$dumpfile("../work/quicksort_tb.fst");
	$dumpvars(0, quicksort_tb);
end

endmodule
