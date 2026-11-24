// dec2.sv - SOLUTION of lab 1.2b: every value of s is described.
module dec2 (
    input  logic [1:0] s,
    output logic [3:0] y
);
    always_comb begin
        case (s)
            2'd0: y = 4'b0001;
            2'd1: y = 4'b0010;
            2'd2: y = 4'b0100;
            default: y = 4'b1000;   // s = 3 (a default also covers x/z in simulation)
        endcase
    end
endmodule
