// adder3.sv - SOLUTION of lab 1.3a
module adder3 (
    input  logic [2:0] a,
    input  logic [2:0] b,
    output logic [2:0] sum,
    output logic       cout
);
    logic [3:0] full;
    assign full = {1'b0, a} + {1'b0, b};   // widen first, so the carry is not lost
    assign sum  = full[2:0];
    assign cout = full[3];
endmodule
