// blink.sv - toggles `out` every half period of BLINK_HZ.
// Parameterized so the same code runs on the board (27 MHz clock) and
// in simulation (tiny clock so the waveform stays short).
module blink #(
    // input clock frequency
    parameter int CLK_HZ = 27_000_000,
    // desired blink frequency
    parameter int BLINK_HZ = 1
)(
    input logic clk,
    // active-low reset
    input logic rst_n,
    // active-high blink signal
    output logic out
);
    // Clock cycles in half a blink period
    localparam int HALF = CLK_HZ / (BLINK_HZ * 2);
    localparam int CNT_W = $clog2(HALF);

    // Initial values are honored by the Gowin FPGA at configuration time
    logic [CNT_W-1:0] cnt;
    logic q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= '0;
            q <= 1'b0;
        end else if (cnt == CNT_W'(HALF - 1)) begin
            cnt <= '0;
            q <= ~q;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    assign out = q;
endmodule
