// =============================================================================
// gain_control.v - sửa debounce, KEY active-low
// KEY[2] nhấn = tăng 1 bước: 0→1→2→...→7→0
// KEY[1] nhấn = reset về 0 (hiển thị 1)
// =============================================================================
module gain_control (
    input  wire        clk,
    input  wire        reset,
    input  wire        key_gain,
    input  wire        key_reset,
    output reg  [2:0]  gain_level
);

// Đồng bộ + phát hiện cạnh xuống cho cả 2 KEY
reg g1,g2,g3, r1,r2,r3;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        g1<=1; g2<=1; g3<=1;
        r1<=1; r2<=1; r3<=1;
    end else begin
        g1<=key_gain;  g2<=g1; g3<=g2;
        r1<=key_reset; r2<=r1; r3<=r2;
    end
end

wire gain_pressed  = (g3 & ~g2);
wire reset_pressed = (r3 & ~r2);

always @(posedge clk or posedge reset) begin
    if (reset)
        gain_level <= 3'd0;
    else if (reset_pressed)
        gain_level <= 3'd0;
    else if (gain_pressed) begin
        if (gain_level == 3'd7) gain_level <= 3'd0;
        else                    gain_level <= gain_level + 1;
    end
end

endmodule