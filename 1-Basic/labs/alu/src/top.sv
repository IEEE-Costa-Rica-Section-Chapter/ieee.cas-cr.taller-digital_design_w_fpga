// top.sv - board wrapper (provided). The sweep gives a (LED sweep, 3 bits) and
// b (3 bits) 4 steps per second: all 64 pairs in 16 seconds.
// Change OP to try the other operations (0 add, 1 and, 2 or, 3 xor), rebuild, program.
// LED0..LED2 = y, LED3 = carry, LED4 = zero, LED5 off.
module top (
    input  logic       clk,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    localparam logic [1:0] OP = 2'd0;

    logic [5:0] v;
    logic [2:0] y;
    logic carry, zero;

    sweep #(.CLK_HZ(27_000_000), .STEP_HZ(4), .W(6)) u_sweep (.clk(clk), .value(v));

    alu3 u_alu (.a(v[2:0]), .b(v[5:3]), .op(OP), .y(y), .carry(carry), .zero(zero));

    assign led = ~{1'b0, zero, carry, y};
endmodule
