// top.sv - board wrapper (provided). Button S1 switches between three light shows.
// BTN_PRESSED: see the note in the button-counter lab (1.4b); flip it if S1 acts when released.
module top (
    input  logic       clk,
    input  logic       btn_s1,
    output logic [5:0] led      // ACTIVE-LOW: 0 = lit
);
    localparam logic BTN_PRESSED = 1'b1;

    // --- button path (module 1.4): raw -> synchronizer -> debounce -> one pulse per press
    logic pressed_raw, pressed_sync, pressed_clean, press;
    assign pressed_raw = (btn_s1 == BTN_PRESSED);
    sync2       u_sync (.clk(clk), .d(pressed_raw), .q(pressed_sync));
    debounce #(.CLK_HZ(27_000_000), .MS(10)) u_deb (.clk(clk), .noisy(pressed_sync), .clean(pressed_clean));
    rise_detect u_rise (.clk(clk), .in(pressed_clean), .pulse(press));

    // --- slow ticks: 8 Hz for the knight, 2 Hz for the blink, 4 Hz for the counter
    logic tick_k, tick_b, tick_c;
    tick_gen #(.CLK_HZ(27_000_000), .TICK_HZ(8)) u_tk (.clk(clk), .rst_n(1'b1), .tick(tick_k));
    tick_gen #(.CLK_HZ(27_000_000), .TICK_HZ(2)) u_tb (.clk(clk), .rst_n(1'b1), .tick(tick_b));
    tick_gen #(.CLK_HZ(27_000_000), .TICK_HZ(4)) u_tc (.clk(clk), .rst_n(1'b1), .tick(tick_c));

    // --- the three patterns
    logic [5:0] knight_leds;
    logic       blink = 1'b0;
    logic [5:0] count = '0;
    knight u_knight (.clk(clk), .rst_n(1'b1), .tick(tick_k), .leds(knight_leds));
    always_ff @(posedge clk) begin
        if (tick_b) blink <= ~blink;
        if (tick_c) count <= count + 1'b1;
    end

    // --- your two modules
    logic [1:0] mode;
    logic [5:0] leds;
    mode_fsm u_mode (.clk(clk), .rst_n(1'b1), .next(press), .mode(mode));
    show     u_show (.mode(mode), .knight(knight_leds), .blink(blink), .count(count), .leds(leds));

    assign led = ~leds;
endmodule
