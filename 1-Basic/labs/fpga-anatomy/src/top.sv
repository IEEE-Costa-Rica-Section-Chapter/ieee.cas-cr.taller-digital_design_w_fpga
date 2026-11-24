// top.sv - board-level wrapper for the Tang Nano 20K.
// Port names must match the names in constraints/tang_nano_20k.cst.
module top (
    // 27 MHz oscillator
    input  logic clk,
    // user button S1, used as reset
    input  logic btn_s1,
    // user LEDs, ACTIVE-LOW (0 = lit)
    output logic [5:0] led
);
    // Logic level on btn_s1 while S1 is pressed.
    // The board examples suggest 1 (pressed = high), but this is inferred, not
    // documented: if LED0 blinks ONLY while S1 is held, change it to 1'b0.
    localparam logic BTN_PRESSED = 1'b1;

    // Active-low reset for the design: 0 while S1 is pressed.
    // Note: releasing the button is asynchronous to clk. That is acceptable for
    // a blinker; a proper reset synchronizer comes in Level 1.
    logic rst_n;
    assign rst_n = (btn_s1 != BTN_PRESSED);

    logic blink_out;

    blink #(
        .CLK_HZ(27_000_000),
        .BLINK_HZ(1)
    ) u_blink (
        .clk(clk),
        .rst_n(rst_n),
        .out(blink_out)
    );

    // LED0 follows the blink signal. LED1..5 stay off.
    assign led = ~{5'b00000, blink_out};
endmodule
