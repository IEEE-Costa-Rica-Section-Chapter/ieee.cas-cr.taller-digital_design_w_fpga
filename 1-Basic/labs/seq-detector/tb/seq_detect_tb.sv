// seq_detect_tb.sv - directed cases, then 4000 random bits against a reference model
// (a 4-bit shift register compared with 1011).
`timescale 1ns/1ps
module seq_detect_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic in = 1'b0;
    logic detect;

    seq_detect dut (.clk(clk), .rst_n(rst_n), .in(in), .detect(detect));

    always #5 clk = ~clk;

    logic [3:0] hist = 4'b0000;
    int total_detects = 0;

    // apply one bit and check the Moore output after the clock edge that samples it
    task automatic send(input logic b);
        in = b;
        @(posedge clk);
        hist = {hist[2:0], b};
        #1;
        if (detect !== (hist == 4'b1011))
            $fatal(1, "after history %b: detect=%b, expected %b", hist, detect, hist == 4'b1011);
        if (detect === 1'b1) total_detects++;
    endtask

    initial begin
        $dumpfile("seq_detect_tb.vcd");
        $dumpvars(0, seq_detect_tb);

        repeat (2) @(posedge clk);
        #1;
        if (detect !== 1'b0) $fatal(1, "detect must be 0 in reset");
        rst_n = 1'b1;

        // directed: plain match, overlapping match, near misses
        send(1); send(0); send(1); send(1);                 // 1011
        send(0); send(1); send(1);                          // ...011 -> second, overlapping match
        send(1); send(0); send(1); send(0); send(1); send(1); // 1010 11 -> 1011 at the end
        send(0); send(0); send(0); send(1); send(1);

        // random
        for (int i = 0; i < 4000; i++) send($urandom_range(0, 1));

        if (total_detects < 100) $fatal(1, "suspiciously few detections (%0d)", total_detects);

        // reset in the middle of a match: back to idle immediately
        send(1); send(0); send(1);
        rst_n = 1'b0; #1;
        if (detect !== 1'b0) $fatal(1, "reset must clear detect");
        hist = 4'b0000;
        @(posedge clk); #1;
        rst_n = 1'b1;
        send(1);                                            // a lone 1 after reset must not complete 101|1
        if (detect !== 1'b0) $fatal(1, "state was not reset");

        $display("PASS");
        $finish;
    end
endmodule
