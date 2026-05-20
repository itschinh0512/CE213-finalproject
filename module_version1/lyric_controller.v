//==============================================================
// LYRIC CONTROLLER MODULE - BƯỚC 5 (đã bỏ debouncer)
//
// Chức năng:
//   - Chế độ thủ công : KEY1 (next), KEY2 (prev) chuyển dòng
//   - Chế độ tự động  : đếm giây bằng counter 50MHz, tự đổi dòng
//   - SW0             : 0 = thủ công, 1 = tự động
//
// Lưu ý KEY trên DE2: active LOW (nhấn = 0, thả = 1)
// => Dùng cạnh xuống (negedge) hoặc detect 1→0 để nhận pulse
//==============================================================

module lyric_controller (
    input  wire        clk,
    input  wire        reset_n,

    // Nút nhấn từ DE2 (active low, đã được hardware debounce)
    input  wire        key_next,   // KEY1: dòng tiếp theo
    input  wire        key_prev,   // KEY2: dòng trước

    // Công tắc chế độ
    input  wire        sw_auto,    // SW0: 1 = tự động

    // Output: chỉ số dòng lyric hiện tại
    output wire [4:0]  lyric_line
);

    //==========================================================
    // THAM SỐ
    //==========================================================
    localparam NUM_LINES    = 28;
    localparam CLOCK_FREQ   = 50_000_000;
    localparam HOLD_SECONDS = 3;
    localparam HOLD_COUNT   = CLOCK_FREQ * HOLD_SECONDS; // 150_000_000
    localparam CNT_AUTO_W   = 28; // ceil(log2(150_000_000)) = 28 bit

    //==========================================================
    // PHÁT HIỆN CẠNH XUỐNG CỦA KEY (active low)
    // KEY nhấn: 1 → 0  →  pulse tại cạnh xuống
    //==========================================================
    reg key_next_prev, key_prev_prev;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            key_next_prev <= 1'b1;   // thả tay = HIGH
            key_prev_prev <= 1'b1;
        end else begin
            key_next_prev <= key_next;
            key_prev_prev <= key_prev;
        end
    end

    // Falling edge: trước HIGH, hiện LOW
    wire pulse_next = key_next_prev & ~key_next;
    wire pulse_prev = key_prev_prev & ~key_prev;

    //==========================================================
    // THANH GHI CHỈ SỐ DÒNG LYRIC
    //==========================================================
    reg [4:0] line_reg;

    assign lyric_line = line_reg;

    //==========================================================
    // COUNTER TỰ ĐỘNG
    //==========================================================
    reg [CNT_AUTO_W-1:0] auto_cnt;

    wire auto_tick = (auto_cnt == HOLD_COUNT - 1);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            auto_cnt <= 0;
        end
        else begin
            if (!sw_auto)
                auto_cnt <= 0;        // chế độ thủ công: giữ reset
            else if (auto_tick)
                auto_cnt <= 0;        // hết giờ: reset để đếm lại
            else
                auto_cnt <= auto_cnt + 1'b1;
        end
    end

    //==========================================================
    // LOGIC CHUYỂN DÒNG
    //==========================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            line_reg <= 5'd0;
        end
        else begin
            if (pulse_next) begin
                if (line_reg == NUM_LINES - 1)
                    line_reg <= 5'd0;
                else
                    line_reg <= line_reg + 5'd1;
            end
            else if (pulse_prev) begin
                if (line_reg == 5'd0)
                    line_reg <= NUM_LINES - 1;
                else
                    line_reg <= line_reg - 5'd1;
            end
            else if (sw_auto && auto_tick) begin
                if (line_reg == NUM_LINES - 1)
                    line_reg <= 5'd0;
                else
                    line_reg <= line_reg + 5'd1;
            end
        end
    end

endmodule