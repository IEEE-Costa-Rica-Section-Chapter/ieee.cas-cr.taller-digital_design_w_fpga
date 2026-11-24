// seq_detect.sv - LAB 1.5: a Moore state machine that detects the bit sequence 1011.
//
//   * One bit arrives per clock cycle on `in`.
//   * detect = 1 while the machine is in the state "I have just seen 1011".
//   * Matches may OVERLAP: in 1011011 the sequence is found twice.
//   * rst_n (asynchronous, active low) returns to S_IDLE.
//
// Draw the state diagram on paper first (5 states: nothing, 1, 10, 101, 1011).
// Then fill in the transitions in the always_comb block, TWO-PROCESS style:
//   always_ff   : the state register (provided)
//   always_comb : next state from (state, in)  <-- your work
//   assign      : the output from the state     (provided, Moore)
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
        next = state;                       // default: stay
        case (state)
            // TODO: one line per state: where do we go when in = 0 and when in = 1?
            default: next = S_IDLE;
        endcase
    end

    assign detect = (state == S_1011);
endmodule
