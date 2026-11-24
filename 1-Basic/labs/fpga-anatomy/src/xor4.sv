// xor4.sv - experiment 1: one 4-input function.
module xor4 (
    input  logic [3:0] a,
    output logic       y
);
    assign y = ^a;      // XOR of all four bits
endmodule
