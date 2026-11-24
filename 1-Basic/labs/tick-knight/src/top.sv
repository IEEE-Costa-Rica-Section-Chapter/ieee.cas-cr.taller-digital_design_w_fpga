// top.sv - board wrapper (provided). The light moves 6 times per second.
module top (
    input  logic       clk,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    logic tick;
    logic [5:0] leds;

    // rst_n tied to 1: no reset button here (the design starts from its initial values)
    tick_gen #(.CLK_HZ(27_000_000), .TICK_HZ(6)) u_tick (.clk(clk), .rst_n(1'b1), .tick(tick));
    knight u_knight (.clk(clk), .rst_n(1'b1), .tick(tick), .leds(leds));

    assign led = ~leds;
endmodule
