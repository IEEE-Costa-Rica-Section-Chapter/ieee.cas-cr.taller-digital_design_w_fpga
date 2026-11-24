// tick_gen.sv - LAB 1.4a (part 1): a clock-enable ("tick") generator.
//
// Produce ONE pulse, exactly ONE clock cycle wide, every CLK_HZ/TICK_HZ clock cycles.
// Rule of the course: never derive a slower clock. Keep using clk everywhere and
// let the slow logic act only on the cycles where tick = 1.
//
// Hints: a counter that counts 0 .. DIV-1 and wraps; tick is 1 when the counter is
// at its last value. $clog2(DIV) gives the number of bits needed.
module tick_gen #(
    parameter int CLK_HZ  = 27_000_000,
    parameter int TICK_HZ = 10
) (
    input  logic clk,
    input  logic rst_n,      // asynchronous, active low
    output logic tick
);
    // TODO
    assign tick = 1'b0;
endmodule
