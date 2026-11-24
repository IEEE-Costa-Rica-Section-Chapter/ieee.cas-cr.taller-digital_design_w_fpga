// gates.sv - SOLUTION of lab 1.2a
module gates (
    input  logic [2:0] x,
    output logic       maj,
    output logic       parity,
    output logic       all_equal
);
    assign maj       = (x[0] & x[1]) | (x[0] & x[2]) | (x[1] & x[2]);
    assign parity    = ^x;
    assign all_equal = (&x) | ~(|x);
endmodule
