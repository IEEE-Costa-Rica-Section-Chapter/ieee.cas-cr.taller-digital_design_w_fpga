// pattern_rom.sv - COURSE HELPER (provided): a bit stream for the detector.
// A 16-bit pattern played from its first bit, one bit per tick, repeating forever.
// It contains 1011 three times, one of them overlapping another.
module pattern_rom (
    input  logic clk,
    input  logic tick,
    output logic bit_out
);
    localparam logic [15:0] PATTERN = 16'b1011_0110_0101_1010;   // played MSB first
    logic [3:0] idx = 4'd0;

    always_ff @(posedge clk)
        if (tick) idx <= idx + 1'b1;

    assign bit_out = PATTERN[4'd15 - idx];
endmodule
