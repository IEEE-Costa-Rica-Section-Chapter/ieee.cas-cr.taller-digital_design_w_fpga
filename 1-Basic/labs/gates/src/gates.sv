// gates.sv - LAB 1.2a: three small circuits on three inputs x[2:0].
//
//   maj        1 when at least TWO of the three inputs are 1   (majority)
//   parity     1 when an ODD number of inputs are 1
//   all_equal  1 when the three inputs are all 0 or all 1
//
// Replace each "assign ... = 1'b0;" with a real expression.
// Hints: & | ^ ~ are bitwise operators; the reduction form ^x XORs all bits of x.
module gates (
    input  logic [2:0] x,
    output logic       maj,
    output logic       parity,
    output logic       all_equal
);
    // TODO: majority
    assign maj = 1'b0;

    // TODO: parity (odd number of ones)
    assign parity = 1'b0;

    // TODO: all three inputs equal
    assign all_equal = 1'b0;
endmodule
