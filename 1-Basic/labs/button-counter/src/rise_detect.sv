// rise_detect.sv - LAB 1.4b (part 3): a pulse on each rising edge.
//
// pulse = 1 for exactly one clock cycle when `in` goes from 0 to 1.
// Hint: remember the previous value of `in` in a flip-flop.
module rise_detect (
    input  logic clk,
    input  logic in,
    output logic pulse
);
    // TODO
    assign pulse = 1'b0;
endmodule
