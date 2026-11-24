// knight.sv - reference copy from module 1.4 (use your own version if you prefer): a light that bounces back and forth.
module knight (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick,
    output logic [5:0] leds       // active-HIGH here: 1 = lit (the top inverts)
);
    logic [2:0] pos = 3'd0;
    logic       down = 1'b0;      // 0 = moving up (0 -> 5), 1 = moving down (5 -> 0)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos  <= 3'd0;
            down <= 1'b0;
        end else if (tick) begin
            if (!down) begin
                if (pos == 3'd5) begin down <= 1'b1; pos <= 3'd4; end
                else             pos <= pos + 1'b1;
            end else begin
                if (pos == 3'd0) begin down <= 1'b0; pos <= 3'd1; end
                else             pos <= pos - 1'b1;
            end
        end
    end

    assign leds = 6'b000001 << pos;
endmodule
