// knight_tb.sv - the light must walk 0,1,2,3,4,5,4,3,2,1,0,1,2,... one step per tick.
`timescale 1ns/1ps
module knight_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic tick = 1'b0;
    logic [5:0] leds;

    knight dut (.clk(clk), .rst_n(rst_n), .tick(tick), .leds(leds));

    always #5 clk = ~clk;

    int expected_pos [0:15] = '{0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5};

    task automatic pulse_tick();
        tick = 1'b1;
        @(posedge clk);
        #1;
        tick = 1'b0;
    endtask

    initial begin
        $dumpfile("knight_tb.vcd");
        $dumpvars(0, knight_tb);

        repeat (2) @(posedge clk);
        #1;
        if (leds !== 6'b000001) $fatal(1, "in reset only LED0 must be lit, got %b", leds);
        rst_n = 1'b1;

        for (int i = 0; i < 16; i++) begin
            if (leds !== (6'b000001 << expected_pos[i]))
                $fatal(1, "step %0d: leds=%b, expected only LED%0d lit", i, leds, expected_pos[i]);
            // with no tick the light must not move
            repeat (3) @(posedge clk);
            #1;
            if (leds !== (6'b000001 << expected_pos[i]))
                $fatal(1, "step %0d: the light moved without a tick (leds=%b)", i, leds);
            pulse_tick();
        end
        $display("PASS");
        $finish;
    end
endmodule
