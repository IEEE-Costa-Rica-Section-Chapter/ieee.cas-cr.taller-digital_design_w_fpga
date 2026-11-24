// gates_tb.sv - exhaustive self-checking testbench: all 8 input combinations.
// The reference is written in a different style (counting ones) on purpose.
`timescale 1ns/1ps
module gates_tb;
    logic [2:0] x;
    logic maj, parity, all_equal;

    gates dut (.x(x), .maj(maj), .parity(parity), .all_equal(all_equal));

    initial begin
        for (int i = 0; i < 8; i++) begin
            int ones;
            x = i[2:0];
            #1;
            ones = $countones(x);
            if (maj !== (ones >= 2))
                $fatal(1, "maj wrong for x=%b: got %b, expected %b", x, maj, ones >= 2);
            if (parity !== (ones % 2 == 1))
                $fatal(1, "parity wrong for x=%b: got %b, expected %b", x, parity, ones % 2 == 1);
            if (all_equal !== (ones == 0 || ones == 3))
                $fatal(1, "all_equal wrong for x=%b: got %b, expected %b", x, all_equal, ones == 0 || ones == 3);
        end
        $display("PASS");
        $finish;
    end
endmodule
