// adder8.sv - experiment 2: an 8-bit adder (combinational).
module adder8 (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [8:0] sum      // 9 bits: the extra bit is the carry out
);
    assign sum = a + b;
endmodule
