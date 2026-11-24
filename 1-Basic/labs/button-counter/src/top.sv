// top.sv - board wrapper (provided). Counts the presses of button S1 on the LEDs
// (binary, LED0 = least significant bit, LED lit = 1).
//
// BTN_PRESSED is the level of btn_s1 while S1 is pressed. It was only inferred
// from Sipeed's examples (module 0, step 0.5 tests it on your board). If your LEDs
// count when you RELEASE the button, or count continuously, flip it to 1'b0.
module top (
    input  logic       clk,
    input  logic       btn_s1,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    localparam logic BTN_PRESSED = 1'b1;

    logic pressed_raw, pressed_sync, pressed_clean, press;
    logic [5:0] count = '0;

    assign pressed_raw = (btn_s1 == BTN_PRESSED);

    sync2       u_sync  (.clk(clk), .d(pressed_raw), .q(pressed_sync));
    debounce #(.CLK_HZ(27_000_000), .MS(10)) u_deb (.clk(clk), .noisy(pressed_sync), .clean(pressed_clean));
    rise_detect u_rise  (.clk(clk), .in(pressed_clean), .pulse(press));

    always_ff @(posedge clk)
        if (press) count <= count + 1'b1;

    assign led = ~count;
endmodule
