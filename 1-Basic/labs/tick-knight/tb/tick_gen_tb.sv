// tick_gen_tb.sv - tick period and width. CLK_HZ=100, TICK_HZ=10 -> one tick per 10 cycles.
`timescale 1ns/1ps
module tick_gen_tb;
    localparam int DIV = 10;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic tick;

    tick_gen #(.CLK_HZ(100), .TICK_HZ(10)) dut (.clk(clk), .rst_n(rst_n), .tick(tick));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tick_gen_tb.vcd");
        $dumpvars(0, tick_gen_tb);

        repeat (3) @(posedge clk);
        #1;
        if (tick !== 1'b0) $fatal(1, "tick must be 0 while in reset, got %b", tick);
        rst_n = 1'b1;

        // after k clock edges the internal count is k mod DIV; tick is high on the last value
        for (int k = 1; k <= 5 * DIV; k++) begin
            @(posedge clk);
            #1;
            if (tick !== (k % DIV == DIV - 1))
                $fatal(1, "after %0d edges tick=%b, expected %b", k, tick, k % DIV == DIV - 1);
        end
        $display("PASS");
        $finish;
    end
endmodule
