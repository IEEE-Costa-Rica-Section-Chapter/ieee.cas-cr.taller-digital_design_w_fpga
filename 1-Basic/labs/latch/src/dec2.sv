// dec2.sv - LAB 1.2b: a 2-to-4 decoder with a bug (one case is missing).
//
//   s = 0 -> y = 0001     s = 1 -> y = 0010
//   s = 2 -> y = 0100     s = 3 -> y = 1000
//
// 1. Run `make stat TOP=dec2` and read the error.
// 2. Run `make sim` and read that failure too.
// 3. Fix the module and run both again.
module dec2 (
    input  logic [1:0] s,
    output logic [3:0] y
);
    always_comb begin
        case (s)
            2'd0: y = 4'b0001;
            2'd1: y = 4'b0010;
            2'd2: y = 4'b0100;
            // the case s = 3 is not described here
        endcase
    end
endmodule
