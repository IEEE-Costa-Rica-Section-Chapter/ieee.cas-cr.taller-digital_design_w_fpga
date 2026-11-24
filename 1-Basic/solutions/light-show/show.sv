// show.sv - SOLUTION of the mini-project, part 2
module show (
    input  logic [1:0] mode,
    input  logic [5:0] knight,
    input  logic       blink,
    input  logic [5:0] count,
    output logic [5:0] leds
);
    always_comb begin
        case (mode)
            2'd0:    leds = knight;
            2'd1:    leds = {6{blink}};
            2'd2:    leds = count;
            default: leds = 6'b000000;
        endcase
    end
endmodule
