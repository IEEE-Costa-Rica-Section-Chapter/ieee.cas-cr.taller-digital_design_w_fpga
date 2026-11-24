// seq_detect.sv - SOLUTION of lab 1.5: Moore detector of the sequence 1011 (overlapping).
module seq_detect (
    input  logic clk,
    input  logic rst_n,
    input  logic in,
    output logic detect
);
    typedef enum logic [2:0] {
        S_IDLE,     // nothing useful seen
        S_1,        // seen ...1
        S_10,       // seen ...10
        S_101,      // seen ...101
        S_1011      // seen 1011: detect
    } state_t;

    state_t state, next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next;
    end

    always_comb begin
        next = state;                       // default: stay (covers every case)
        case (state)
            S_IDLE: if (in) next = S_1;                     // else stay in S_IDLE
            S_1:    if (!in) next = S_10;                   // 1 then 1 = still "...1": stay
            S_10:   if (in) next = S_101; else next = S_IDLE;
            S_101:  if (in) next = S_1011; else next = S_10;
            S_1011: if (in) next = S_1; else next = S_10;   // overlap: the last 1 starts a new match
            default: next = S_IDLE;
        endcase
    end

    assign detect = (state == S_1011);
endmodule
