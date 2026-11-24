// sync2_tb.sv - q must equal d delayed by exactly two clock cycles.
`timescale 1ns/1ps
module sync2_tb;
    logic clk = 1'b0;
    logic d = 1'b0;
    logic q;

    sync2 dut (.clk(clk), .d(d), .q(q));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sync2_tb.vcd");
        $dumpvars(0, sync2_tb);
        repeat (3) @(posedge clk);
        #1;
        if (q !== 1'b0) $fatal(1, "q should start at 0, got %b", q);

        d = 1'b1;                       // change just after an edge
        #1;
        if (q !== 1'b0) $fatal(1, "q must not follow d immediately, got %b", q);
        @(posedge clk); #1;
        if (q !== 1'b0) $fatal(1, "after 1 clock edge q must still be 0 (two flip-flops), got %b", q);
        @(posedge clk); #1;
        if (q !== 1'b1) $fatal(1, "after 2 clock edges q must be 1, got %b", q);

        d = 1'b0;
        @(posedge clk); #1;
        if (q !== 1'b1) $fatal(1, "falling: after 1 edge q must still be 1, got %b", q);
        @(posedge clk); #1;
        if (q !== 1'b0) $fatal(1, "falling: after 2 edges q must be 0, got %b", q);

        $display("PASS");
        $finish;
    end
endmodule
