// rise_detect.sv - reference copy from module 1.4 (use your own version if you prefer): a one-cycle pulse on each rising edge.
module rise_detect (
    input  logic clk,
    input  logic in,
    output logic pulse
);
    logic prev = 1'b0;

    always_ff @(posedge clk) prev <= in;

    assign pulse = in & ~prev;
endmodule
