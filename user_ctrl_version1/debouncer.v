// debouncer.v
// Filters mechanical bounce on a single active-low KEY button.
// Emits a single-cycle active-high pulse (out_pulse) on each clean press.
// Sampling rate = clk / (CLKS_PER_MS * 20) — stable after 20 ms.

module debouncer #(
    parameter CLKS_PER_MS = 50_000   // 50 MHz → 1 ms tick
)(
    input  wire clk,
    input  wire rst,
    input  wire key_n,       // active-low raw button input
    output reg  out_pulse    // single-cycle high pulse on clean press
);

    // ----------------------------------------------------------------
    // 1. Generate a 1 ms tick from the 50 MHz clock
    // ----------------------------------------------------------------
    localparam TICK_MAX = CLKS_PER_MS - 1;
    reg [$clog2(CLKS_PER_MS)-1:0] tick_cnt;
    reg ms_tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt <= 0;
            ms_tick  <= 1'b0;
        end else if (tick_cnt == TICK_MAX) begin
            tick_cnt <= 0;
            ms_tick  <= 1'b1;
        end else begin
            tick_cnt <= tick_cnt + 1;
            ms_tick  <= 1'b0;
        end
    end

    // ----------------------------------------------------------------
    // 2. Sample the (inverted) button every ms tick into a shift register
    //    Four consecutive 1s = stable press
    // ----------------------------------------------------------------
    reg [3:0] shift_reg;
    reg       stable;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 4'b0000;
            stable    <= 1'b0;
        end else if (ms_tick) begin
            shift_reg <= {shift_reg[2:0], ~key_n};  // invert: active-low → active-high
            stable    <= (shift_reg == 4'b1111);     // four stable highs
        end
    end

    // ----------------------------------------------------------------
    // 3. Edge detect on stable to emit exactly one pulse
    // ----------------------------------------------------------------
    reg stable_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_prev <= 1'b0;
            out_pulse   <= 1'b0;
        end else begin
            stable_prev <= stable;
            out_pulse   <= stable & ~stable_prev;   // rising edge → one-cycle pulse
        end
    end

endmodule