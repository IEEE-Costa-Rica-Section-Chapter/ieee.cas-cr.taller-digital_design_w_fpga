// alu3.sv - SOLUTION of lab 1.3b
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
        carry = 1'b0;                 // default: only the addition sets the carry
        case (op)
            2'b00:   begin y = sum;   carry = cout; end
            2'b01:   y = a & b;
            2'b10:   y = a | b;
            default: y = a ^ b;       // 2'b11
        endcase
    end

    assign zero = (y == 3'b000);
endmodule
