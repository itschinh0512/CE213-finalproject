// =============================================================================
// i2s_receiver.v - sửa lại hoàn toàn
// Vấn đề cũ: left_data latch tại lr_rise, right_data tại lr_fall
//            → 2 kênh lệch nhau 1 frame → tiếng bị méo/mất
// Sửa: dùng buffer nội bộ, chỉ xuất ra ngoài khi có đủ CẢ HAI kênh
// =============================================================================
module i2s_receiver (
    input  wire        clk,
    input  wire        reset,
    input  wire        bclk,
    input  wire        lrclk,
    input  wire        sdata,
    output reg  [15:0] left_data,
    output reg  [15:0] right_data,
    output reg         data_valid
);

// ── Đồng bộ hoá tín hiệu bên ngoài vào clock 50MHz ──────────────────────────
reg bclk_r1, bclk_r2, lr_r1, lr_r2;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        bclk_r1<=0; bclk_r2<=0;
        lr_r1  <=0; lr_r2  <=0;
    end else begin
        bclk_r1 <= bclk;   bclk_r2 <= bclk_r1;
        lr_r1   <= lrclk;  lr_r2   <= lr_r1;
    end
end

wire bclk_rise = ( bclk_r1 & ~bclk_r2);
wire lr_rise   = ( lr_r1   & ~lr_r2);   // 0→1: kết thúc LEFT, bắt đầu RIGHT
wire lr_fall   = (~lr_r1   &  lr_r2);   // 1→0: kết thúc RIGHT, bắt đầu LEFT

// ── Shift register nhận bit nối tiếp ────────────────────────────────────────
reg [15:0] shift_reg;
reg [4:0]  bit_cnt;
reg        skip_first;

// Buffer giữ left tạm thời cho đến khi right xong
reg [15:0] left_buf;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        shift_reg  <= 0;
        bit_cnt    <= 0;
        skip_first <= 0;
        left_buf   <= 0;
        left_data  <= 0;
        right_data <= 0;
        data_valid <= 0;
    end else begin
        data_valid <= 0; // default: không có data mới

        // ── Xử lý cạnh LRCLK ──────────────────────────────────────────────
        if (lr_rise) begin
            // Kết thúc kênh LEFT → lưu vào buffer tạm
            left_buf   <= shift_reg;
            shift_reg  <= 0;
            bit_cnt    <= 0;
            skip_first <= 1;  // I2S: bỏ qua 1 BCLK đầu tiên
        end

        if (lr_fall) begin
            // Kết thúc kênh RIGHT → xuất cả 2 kênh cùng lúc
            left_data  <= left_buf;   // kênh trái từ buffer
            right_data <= shift_reg;  // kênh phải vừa xong
            data_valid <= 1'b1;       // báo có sample mới
            shift_reg  <= 0;
            bit_cnt    <= 0;
            skip_first <= 1;
        end

        // ── Nhận từng bit trên cạnh lên BCLK ─────────────────────────────
        if (bclk_rise && !lr_rise && !lr_fall) begin
            if (skip_first) begin
                skip_first <= 0;  // bỏ qua bit trễ MSB theo chuẩn I2S
            end else if (bit_cnt < 16) begin
                shift_reg <= {shift_reg[14:0], sdata};
                bit_cnt   <= bit_cnt + 1;
            end
        end
    end
end

endmodule