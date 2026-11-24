// tick_gen.sv - SOLUTION of lab 1.4a: a clock-enable ("tick") generator.
// One pulse, exactly one clock cycle wide, every CLK_HZ/TICK_HZ cycles.
// We never make a slower clock: everything keeps using clk and only acts when tick = 1.
module tick_gen #(
    parameter int CLK_HZ  = 27_000_000,
    parameter int TICK_HZ = 10
) (
    input  logic clk,
    input  logic rst_n,
    output logic tick
);
    localparam int DIV = CLK_HZ / TICK_HZ;
    localparam int W   = $clog2(DIV);
    localparam logic [W-1:0] LAST = W'(DIV - 1);

    logic [W-1:0] cnt = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          cnt <= '0;
        else if (cnt == LAST) cnt <= '0;
        else                  cnt <= cnt + 1'b1;
    end

    assign tick = (cnt == LAST);
endmodule
