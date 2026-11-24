// alu3.sv - LAB 1.3b: a small ALU on 3-bit operands.
//
//   op = 00  y = a + b (mod 8), carry = carry out of the addition
//   op = 01  y = a & b          carry = 0
//   op = 10  y = a | b          carry = 0
//   op = 11  y = a ^ b          carry = 0
//   zero = 1 when y == 0
//
// The adder is already instantiated for you. Rules for always_comb:
//   * give EVERY output a value in EVERY branch (or a default before the case),
//     otherwise the tools infer a latch (see lab 1.2b).
module alu3 (
    input  logic [2:0] a,
    input  logic [2:0] b,
    input  logic [1:0] op,
    output logic [2:0] y,
    output logic       carry,
    output logic       zero
);
    logic [2:0] sum;
    logic       cout;
    adder3 u_add (.a(a), .b(b), .sum(sum), .cout(cout));

    always_comb begin
        // TODO: choose y and carry according to op
        y     = 3'b000;
        carry = 1'b0;
    end

    // TODO: zero flag
    assign zero = 1'b0;
endmodule
