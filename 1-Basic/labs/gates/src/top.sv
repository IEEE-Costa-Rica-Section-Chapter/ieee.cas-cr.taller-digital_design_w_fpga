// top.sv - board wrapper (provided). Do not edit.
// LED0..LED2 show the input x, LED3 = maj, LED4 = parity, LED5 = all_equal.
// The sweep helper changes x twice per second: the whole truth table in 4 s.
module top (
    input  logic       clk,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    logic [2:0] x;
    logic maj, parity, all_equal;

    sweep #(.CLK_HZ(27_000_000), .STEP_HZ(2), .W(3)) u_sweep (.clk(clk), .value(x));

    gates u_gates (.x(x), .maj(maj), .parity(parity), .all_equal(all_equal));

    assign led = ~{all_equal, parity, maj, x};
endmodule
