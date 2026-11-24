// adder3_tb.sv - exhaustive: all 64 (a, b) pairs against the + operator.
`timescale 1ns/1ps
module adder3_tb;
    logic [2:0] a, b, sum;
    logic cout;

    adder3 dut (.a(a), .b(b), .sum(sum), .cout(cout));

    initial begin
        for (int i = 0; i < 64; i++) begin
            logic [3:0] expect_full;
            a = i[2:0];
            b = i[5:3];
            #1;
            expect_full = {1'b0, a} + {1'b0, b};
            if ({cout, sum} !== expect_full)
                $fatal(1, "a=%0d b=%0d: got cout=%b sum=%0d, expected %0d", a, b, cout, sum, expect_full);
        end
        $display("PASS");
        $finish;
    end
endmodule
