// dec2_tb.sv - self-checking testbench for the decoder (all 4 inputs, in order).
`timescale 1ns/1ps
module dec2_tb;
    logic [1:0] s;
    logic [3:0] y;

    dec2 dut (.s(s), .y(y));

    initial begin
        for (int i = 0; i < 4; i++) begin
            s = i[1:0];
            #1;
            if (y !== (4'b0001 << i))
                $fatal(1, "s=%0d: got y=%b, expected %b", i, y, 4'b0001 << i);
        end
        $display("PASS");
        $finish;
    end
endmodule
