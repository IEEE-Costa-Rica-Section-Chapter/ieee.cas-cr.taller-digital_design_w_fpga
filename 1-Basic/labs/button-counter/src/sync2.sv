// sync2.sv - LAB 1.4b (part 1): two-flip-flop synchronizer.
//
// A button is not synchronous to clk. Sampling it directly can leave a flip-flop
// metastable. Pass it through TWO flip-flops in series: q must be d delayed by
// exactly two clock cycles.
module sync2 (
    input  logic clk,
    input  logic d,
    output logic q
);
    // TODO: two flip-flops (use always_ff and non-blocking <=)
    assign q = d;
endmodule
