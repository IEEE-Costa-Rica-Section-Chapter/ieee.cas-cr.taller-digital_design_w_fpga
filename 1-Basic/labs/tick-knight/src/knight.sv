// knight.sv - LAB 1.4a (part 2): a light that bounces back and forth.
//
// leds is ACTIVE-HIGH here (1 = lit); the top inverts it for the board.
// On every tick the lit LED moves one place:
//   0,1,2,3,4,5,4,3,2,1,0,1,2,...   (it turns around at both ends, no repeated end)
// When tick = 0 nothing changes. rst_n puts the light back at LED0.
//
// Hints: a 3-bit position and a direction flip-flop; leds = 6'b000001 << pos.
module knight (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick,
    output logic [5:0] leds
);
    // TODO: state (position, direction) and its update on tick
    assign leds = 6'b000001;
endmodule
