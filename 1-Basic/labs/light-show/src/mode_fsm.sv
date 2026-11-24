// mode_fsm.sv - MINI-PROJECT part 1: which light show is running?
//
// Three modes, 0 -> 1 -> 2 -> 0 -> ..., advancing by ONE step on every cycle
// where `next` = 1 (a one-cycle pulse from the debounced button).
// Between pulses the mode must not change. rst_n returns to mode 0.
//
// Use a two-process state machine as in module 1.5. Moore: `mode` depends only on the state.
module mode_fsm (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       next,
    output logic [1:0] mode
);
    // TODO: states, state register, next-state logic, output
    assign mode = 2'd0;
endmodule
