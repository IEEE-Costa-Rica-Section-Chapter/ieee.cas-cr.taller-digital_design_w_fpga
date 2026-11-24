// top.sv - board wrapper (provided). The sweep walks s through 0,1,2,3 once per
// second; the decoder output is shown on LED0..LED3 (LED lit = 1).
module top (
    input  logic       clk,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    logic [1:0] s;
    logic [3:0] y;

    sweep #(.CLK_HZ(27_000_000), .STEP_HZ(1), .W(2)) u_sweep (.clk(clk), .value(s));

    dec2 u_dec (.s(s), .y(y));

    assign led = ~{2'b00, y};
endmodule
