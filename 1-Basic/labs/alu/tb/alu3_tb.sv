// alu3_tb.sv - exhaustive: all 256 combinations of a, b, op against a reference
// function written in the testbench.
`timescale 1ns/1ps
module alu3_tb;
    logic [2:0] a, b, y;
    logic [1:0] op;
    logic carry, zero;

    alu3 dut (.a(a), .b(b), .op(op), .y(y), .carry(carry), .zero(zero));

    initial begin
        for (int i = 0; i < 256; i++) begin
            logic [3:0] full;
            logic [2:0] ey;
            logic       ec;
            a  = i[2:0];
            b  = i[5:3];
            op = i[7:6];
            #1;
            full = {1'b0, a} + {1'b0, b};
            case (op)
                2'b00: begin ey = full[2:0]; ec = full[3]; end
                2'b01: begin ey = a & b;     ec = 1'b0;    end
                2'b10: begin ey = a | b;     ec = 1'b0;    end
                default: begin ey = a ^ b;   ec = 1'b0;    end
            endcase
            if (y !== ey)
                $fatal(1, "op=%b a=%0d b=%0d: y=%0d, expected %0d", op, a, b, y, ey);
            if (carry !== ec)
                $fatal(1, "op=%b a=%0d b=%0d: carry=%b, expected %b", op, a, b, carry, ec);
            if (zero !== (ey == 3'b000))
                $fatal(1, "op=%b a=%0d b=%0d: zero=%b, expected %b", op, a, b, zero, ey == 3'b000);
        end
        $display("PASS");
        $finish;
    end
endmodule
