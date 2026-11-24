// mode_fsm.sv - SOLUTION of the mini-project, part 1
module mode_fsm (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       next,
    output logic [1:0] mode
);
    typedef enum logic [1:0] { M_KNIGHT, M_BLINK, M_COUNT } state_t;
    state_t state, nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= M_KNIGHT;
        else        state <= nxt;
    end

    always_comb begin
        nxt = state;
        if (next) begin
            case (state)
                M_KNIGHT: nxt = M_BLINK;
                M_BLINK:  nxt = M_COUNT;
                default:  nxt = M_KNIGHT;
            endcase
        end
    end

    assign mode = state;
endmodule
