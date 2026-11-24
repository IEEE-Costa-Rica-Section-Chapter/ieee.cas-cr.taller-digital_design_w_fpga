// show.sv - MINI-PROJECT part 2: choose what the LEDs display. Purely combinational.
//
//   mode 0 : the knight-rider pattern      -> leds = knight
//   mode 1 : every LED blinks together     -> leds = {6{blink}}
//   mode 2 : a binary counter              -> leds = count
//   mode 3 : not used, all LEDs off        -> leds = 6'b000000
//
// leds is ACTIVE-HIGH (1 = lit); the top inverts it. No latches: cover every mode.
module show (
    input  logic [1:0] mode,
    input  logic [5:0] knight,
    input  logic       blink,
    input  logic [5:0] count,
    output logic [5:0] leds
);
    // TODO
    assign leds = 6'b000000;
endmodule
