// top.sv - board wrapper (provided). A 16-bit pattern is played at 2 bits per second.
// LED0 = current input bit, LED1 = detect, LED2..LED5 = the last four bits (newest on LED2).
// LED lit = 1. Watch LED1 light up when LED5..LED2 show 1 0 1 1 (reading LED5 first).
module top (
    input  logic       clk,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    logic tick, bit_in, detect;
    logic [3:0] last4 = '0;

    tick_gen    #(.CLK_HZ(27_000_000), .TICK_HZ(2)) u_tick (.clk(clk), .rst_n(1'b1), .tick(tick));
    pattern_rom u_rom   (.clk(clk), .tick(tick), .bit_out(bit_in));
    seq_detect  u_det   (.clk(clk), .rst_n(1'b1), .in(bit_in), .detect(detect));

    // the detector samples `in` on every clock; the display samples it once per tick
    always_ff @(posedge clk)
        if (tick) last4 <= {last4[2:0], bit_in};

    assign led = ~{last4, detect, bit_in};
endmodule
