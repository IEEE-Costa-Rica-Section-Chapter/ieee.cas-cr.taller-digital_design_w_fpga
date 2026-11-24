// sweep.sv - COURSE HELPER (provided). A slow counter that walks through every
// combination of W input bits, STEP_HZ combinations per second, so that a purely
// combinational design can be watched on the LEDs without any button.
// You will write a counter like this one yourself in module 1.4.
module sweep #(
    parameter int CLK_HZ  = 27_000_000,
    parameter int STEP_HZ = 4,
    parameter int W       = 6
) (
    input  logic         clk,
    output logic [W-1:0] value
);
    localparam int DIV = CLK_HZ / STEP_HZ;
    localparam int DW  = $clog2(DIV);
    localparam logic [DW-1:0] LAST = DW'(DIV - 1);

    logic [DW-1:0] cnt = '0;
    logic [W-1:0]  v   = '0;

    always_ff @(posedge clk) begin
        if (cnt == LAST) begin
            cnt <= '0;
            v   <= v + 1'b1;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    assign value = v;
endmodule
