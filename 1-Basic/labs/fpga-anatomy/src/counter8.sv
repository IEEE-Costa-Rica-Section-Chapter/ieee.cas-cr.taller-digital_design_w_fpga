// counter8.sv - experiment 3: an 8-bit counter (sequential).
module counter8 (
    input  logic       clk,
    input  logic       rst_n,   // asynchronous, active low
    output logic [7:0] q
);
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) q <= '0;
        else        q <= q + 8'd1;
endmodule
