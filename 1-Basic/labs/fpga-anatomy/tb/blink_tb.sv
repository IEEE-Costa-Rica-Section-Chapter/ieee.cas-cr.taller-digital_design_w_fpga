// blink_tb.sv - self-checking testbench for blink.
// Convention for every testbench in this course:
//   * print PASS and $finish when everything is correct
//   * call $fatal on the first error (make sim then stops with an error)
`timescale 1ns/1ps

module blink_tb;
    // tiny clock: half period = 50 cycles
    localparam int CLK_HZ   = 100;
    localparam int BLINK_HZ = 1;
    localparam int HALF     = CLK_HZ / (BLINK_HZ * 2);

    logic clk = 1'b0;
    // start in reset, like a pressed button
    logic rst_n = 1'b0;
    logic out;

    blink #(.CLK_HZ(CLK_HZ), .BLINK_HZ(BLINK_HZ)) dut (
        .clk(clk), .rst_n(rst_n), .out(out)
    );

    // 100 MHz in simulation time
    always #5 clk = ~clk;

    initial begin
        // open with: make wave
        $dumpfile("blink_tb.vcd");
        $dumpvars(0, blink_tb);

        // Registers update on the clock edge, so look slightly AFTER it (#1)

        // 1. while the reset is held, the output stays low
        repeat (3) @(posedge clk); #1;
        if (out !== 1'b0) $fatal(1, "out should be 0 while in reset, got %b", out);
        rst_n = 1'b1;

        // 2. after release it blinks: high for HALF cycles, then low
        repeat (HALF) @(posedge clk); #1;
        if (out !== 1'b1) $fatal(1, "expected out=1 after half period, got %b", out);

        repeat (HALF) @(posedge clk); #1;
        if (out !== 1'b0) $fatal(1, "expected out=0 after full period, got %b", out);

        // 3. reset in the middle of a blink: the reset is asynchronous,
        //    so out falls immediately, without waiting for a clock edge
        repeat (HALF) @(posedge clk); #1;
        if (out !== 1'b1) $fatal(1, "expected out=1 before the reset, got %b", out);
        rst_n = 1'b0; #1;
        if (out !== 1'b0) $fatal(1, "out should drop right away on reset, got %b", out);
        repeat (2) @(posedge clk); #1;
        rst_n = 1'b1;

        // 4. the count restarts from zero after the reset
        repeat (HALF) @(posedge clk); #1;
        if (out !== 1'b1) $fatal(1, "blink should restart after reset, got %b", out);

        $display("PASS");
        $finish;
    end
endmodule
