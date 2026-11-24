// rise_detect_tb.sv - one pulse of one cycle per rising edge, nothing on falling edges.
`timescale 1ns/1ps
module rise_detect_tb;
    logic clk = 1'b0;
    logic in = 1'b0;
    logic pulse;

    rise_detect dut (.clk(clk), .in(in), .pulse(pulse));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("rise_detect_tb.vcd");
        $dumpvars(0, rise_detect_tb);
        repeat (3) @(posedge clk);
        #1;
        if (pulse !== 1'b0) $fatal(1, "no pulse expected while in = 0, got %b", pulse);

        in = 1'b1; #1;
        if (pulse !== 1'b1) $fatal(1, "pulse expected right after the rising edge, got %b", pulse);
        @(posedge clk); #1;
        if (pulse !== 1'b0) $fatal(1, "pulse must last ONE cycle only, still %b", pulse);
        repeat (3) begin @(posedge clk); #1; if (pulse !== 1'b0) $fatal(1, "pulse while in is held high"); end

        in = 1'b0; #1;
        if (pulse !== 1'b0) $fatal(1, "no pulse expected on a falling edge");
        repeat (2) @(posedge clk);
        #1;
        in = 1'b1; #1;
        if (pulse !== 1'b1) $fatal(1, "second rising edge must pulse again");

        $display("PASS");
        $finish;
    end
endmodule
