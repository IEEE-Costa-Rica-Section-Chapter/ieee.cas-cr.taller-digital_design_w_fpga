// debounce_tb.sv - CLK_HZ=1000, MS=10 -> LIMIT = 10 cycles.
// Bouncing shorter than LIMIT must be ignored; a stable level must pass after exactly LIMIT cycles.
`timescale 1ns/1ps
module debounce_tb;
    localparam int LIMIT = 10;

    logic clk = 1'b0;
    logic noisy = 1'b0;
    logic clean;

    debounce #(.CLK_HZ(1000), .MS(10)) dut (.clk(clk), .noisy(noisy), .clean(clean));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("debounce_tb.vcd");
        $dumpvars(0, debounce_tb);
        repeat (3) @(posedge clk);
        #1;
        if (clean !== 1'b0) $fatal(1, "clean should start at 0, got %b", clean);

        // contact bounce: 1 for 4 cycles, 0 for 4 cycles, repeated. Never LIMIT in a row.
        repeat (5) begin
            noisy = 1'b1; repeat (4) @(posedge clk);
            noisy = 1'b0; repeat (4) @(posedge clk);
        end
        #1;
        if (clean !== 1'b0) $fatal(1, "bouncing was not filtered out: clean=%b", clean);

        // a real press: stays high
        noisy = 1'b1;
        repeat (LIMIT - 1) @(posedge clk);
        #1;
        if (clean !== 1'b0) $fatal(1, "clean changed too early (before %0d cycles)", LIMIT);
        @(posedge clk); #1;
        if (clean !== 1'b1) $fatal(1, "clean should be 1 after %0d stable cycles, got %b", LIMIT, clean);

        // release with bounce
        noisy = 1'b0; repeat (3) @(posedge clk);
        noisy = 1'b1; repeat (3) @(posedge clk);
        #1;
        if (clean !== 1'b1) $fatal(1, "release bounce must not change clean");
        noisy = 1'b0;
        repeat (LIMIT - 1) @(posedge clk);
        #1;
        if (clean !== 1'b1) $fatal(1, "clean fell too early");
        @(posedge clk); #1;
        if (clean !== 1'b0) $fatal(1, "clean should be 0 after %0d stable cycles of release, got %b", LIMIT, clean);

        $display("PASS");
        $finish;
    end
endmodule
