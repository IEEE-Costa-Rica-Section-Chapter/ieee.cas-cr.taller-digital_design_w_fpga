// rise_detect.sv - SOLUTION of lab 1.4b: a one-cycle pulse on each rising edge.
module rise_detect (
    input  logic clk,
    input  logic in,
    output logic pulse
);
    logic prev = 1'b0;

    always_ff @(posedge clk) prev <= in;

    assign pulse = in & ~prev;
endmodule
