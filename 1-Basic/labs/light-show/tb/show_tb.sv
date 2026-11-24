// show_tb.sv - exhaustive over the mode and a set of input patterns.
`timescale 1ns/1ps
module show_tb;
    logic [1:0] mode;
    logic [5:0] knight, count, leds;
    logic blink;

    show dut (.mode(mode), .knight(knight), .blink(blink), .count(count), .leds(leds));

    initial begin
        for (int m = 0; m < 4; m++) begin
            for (int k = 0; k < 64; k += 7) begin
                for (int b = 0; b < 2; b++) begin
                    logic [5:0] expect_leds;
                    mode   = m[1:0];
                    knight = k[5:0];
                    count  = ~k[5:0];
                    blink  = b[0];
                    #1;
                    case (m)
                        0: expect_leds = knight;
                        1: expect_leds = {6{blink}};
                        2: expect_leds = count;
                        default: expect_leds = 6'b000000;
                    endcase
                    if (leds !== expect_leds)
                        $fatal(1, "mode=%0d knight=%b blink=%b count=%b: leds=%b, expected %b", m, knight, blink, count, leds, expect_leds);
                end
            end
        end
        $display("PASS");
        $finish;
    end
endmodule
