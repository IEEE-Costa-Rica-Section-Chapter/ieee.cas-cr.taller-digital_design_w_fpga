// sync2.sv - reference copy from module 1.4 (use your own version if you prefer): two-flip-flop synchronizer.
// The first flip-flop may go metastable; the second gives it a full cycle to settle.
module sync2 (
    input  logic clk,
    input  logic d,
    output logic q
);
    logic meta = 1'b0;
    logic q_r  = 1'b0;

    always_ff @(posedge clk) begin
        meta <= d;
        q_r  <= meta;
    end

    assign q = q_r;
endmodule
