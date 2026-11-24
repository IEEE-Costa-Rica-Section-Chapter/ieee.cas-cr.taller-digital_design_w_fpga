// mode_fsm_tb.sv - the mode cycles 0,1,2,0,1,... one step per `next` pulse.
`timescale 1ns/1ps
module mode_fsm_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic next = 1'b0;
    logic [1:0] mode;

    mode_fsm dut (.clk(clk), .rst_n(rst_n), .next(next), .mode(mode));

    always #5 clk = ~clk;

    task automatic press();
        next = 1'b1;
        @(posedge clk);
        #1;
        next = 1'b0;
    endtask

    initial begin
        $dumpfile("mode_fsm_tb.vcd");
        $dumpvars(0, mode_fsm_tb);
        repeat (2) @(posedge clk);
        #1;
        if (mode !== 2'd0) $fatal(1, "mode must be 0 in reset, got %0d", mode);
        rst_n = 1'b1;

        for (int i = 0; i < 8; i++) begin
            if (mode !== 2'(i % 3)) $fatal(1, "after %0d presses mode=%0d, expected %0d", i, mode, i % 3);
            repeat (3) @(posedge clk);
            #1;
            if (mode !== 2'(i % 3)) $fatal(1, "mode changed without a press (mode=%0d)", mode);
            press();
        end

        // reset in the middle: back to mode 0 at once
        press();
        rst_n = 1'b0; #1;
        if (mode !== 2'd0) $fatal(1, "reset must give mode 0, got %0d", mode);
        $display("PASS");
        $finish;
    end
endmodule
