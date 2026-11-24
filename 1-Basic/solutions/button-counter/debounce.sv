// debounce.sv - SOLUTION of lab 1.4b.
// `clean` only follows `noisy` after noisy has differed from clean for LIMIT
// consecutive clock cycles. Any bounce back resets the count.
module debounce #(
    parameter int CLK_HZ = 27_000_000,
    parameter int MS     = 10
) (
    input  logic clk,
    input  logic noisy,
    output logic clean
);
    localparam int LIMIT = (CLK_HZ / 1000) * MS;
    localparam int W     = $clog2(LIMIT);
    localparam logic [W-1:0] LAST = W'(LIMIT - 1);

    logic [W-1:0] cnt = '0;
    logic         c   = 1'b0;

    always_ff @(posedge clk) begin
        if (noisy == c) begin
            cnt <= '0;
        end else if (cnt == LAST) begin
            c   <= noisy;
            cnt <= '0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    assign clean = c;
endmodule
