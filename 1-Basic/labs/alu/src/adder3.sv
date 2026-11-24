// adder3.sv - LAB 1.3a: a 3-bit adder with carry out.
//   {cout, sum} = a + b        (a, b, sum are 3 bits wide, cout is 1 bit)
// Hint: the sum of two 3-bit numbers needs 4 bits. Write the + on a 4-bit result,
// or build it from three full adders if you want to practise `generate`.
module adder3 (
    input  logic [2:0] a,
    input  logic [2:0] b,
    output logic [2:0] sum,
    output logic       cout
);
    // TODO
    assign sum  = 3'b000;
    assign cout = 1'b0;
endmodule
