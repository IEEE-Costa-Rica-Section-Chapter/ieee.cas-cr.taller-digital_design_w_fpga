// debounce.sv - LAB 1.4b (part 2): remove contact bounce.
//
// `clean` follows `noisy`, but only after noisy has been DIFFERENT from clean for
// LIMIT consecutive clock cycles (LIMIT = (CLK_HZ/1000) * MS). If noisy goes back
// to the value of clean before that, the count restarts from zero.
//
// Hints: a counter that clears when noisy == clean, otherwise counts; when it
// reaches LIMIT-1, copy noisy into the stored value of clean.
module debounce #(
    parameter int CLK_HZ = 27_000_000,
    parameter int MS     = 10
) (
    input  logic clk,
    input  logic noisy,
    output logic clean
);
    localparam int LIMIT = (CLK_HZ / 1000) * MS;

    // TODO
    assign clean = noisy;
endmodule
