//==============================================================
// TEXT RENDERER MODULE - BƯỚC 4 (phiên bản hỗ trợ Scale)
//
// Thay đổi so với bản gốc:
//   [Mới] Thêm localparam SCALE để phóng to chữ
//         SCALE=1 → font 8x16  (gốc, 80 cột x 30 hàng)
//         SCALE=2 → font 16x32 (gấp đôi, 40 cột x 15 hàng)
//         SCALE=3 → font 24x48 (gấp ba, ~26 cột x 10 hàng)
//   [Sửa] char_col, char_row_scr, font_x, font_y tính có chia SCALE
//   [Sửa] LYRIC_ROW, LYRIC_COL_START, LYRIC_COL_END
//         tính lại theo kích thước ký tự mới
//
// Pipeline (không đổi so với bản gốc):
//   Tầng 0 (combinational): tính tọa độ → addr Lyric ROM
//   Tầng 1 (posedge clk)  : Lyric ROM → char_out → addr Font ROM
//   Tầng 2 (posedge clk)  : Font ROM  → font_row_data → xuất RGB
//   Delay compensation    : font_x, video_on, in_lyric_zone
//                           được pipeline 2 chu kỳ song song
//
// Thông số màn: 640x480 @60Hz
// Font gốc: 8x16
//==============================================================

module text_renderer (
    input  wire        clk,
    input  wire        reset_n,

    // Từ vga_sync
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,

    // Chỉ số dòng lyric hiện tại (từ lyric_controller)
    input  wire [4:0]  lyric_line,

    // Output màu VGA 4-bit mỗi kênh
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    //==========================================================
    // THAM SỐ
    //==========================================================
    localparam FONT_W     = 8;    // pixel/ký tự gốc theo chiều ngang
    localparam FONT_H     = 16;   // pixel/ký tự gốc theo chiều dọc
    localparam LINE_WIDTH = 40;   // ký tự/dòng lyric (khớp lyric_rom)

    // *** ĐIỀU CHỈNH Ở ĐÂY ĐỂ THAY ĐỔI CỠ CHỮ ***
    // SCALE=1 → 8x16  (80 cột × 30 hàng)
    // SCALE=2 → 16x32 (40 cột × 15 hàng)  ← đang dùng
    // SCALE=3 → 24x48 (~26 cột × 10 hàng)
    localparam SCALE      = 2;

    // Kích thước ký tự sau khi scale
    localparam CHAR_W     = FONT_W * SCALE;   // 16 (SCALE=2)
    localparam CHAR_H     = FONT_H * SCALE;   // 32 (SCALE=2)

    // Số cột và hàng ký tự trên màn hình sau khi scale
    // SCALE=2: 640/16 = 40 cột, 480/32 = 15 hàng
    localparam SCREEN_COLS = 640 / CHAR_W;    // 40 (SCALE=2)
    localparam SCREEN_ROWS = 480 / CHAR_H;    // 15 (SCALE=2)

    // Hàng ký tự dùng để hiển thị lyric (căn giữa theo chiều dọc)
    // SCALE=2: SCREEN_ROWS=15 → hàng giữa = 7
    // SCALE=1: SCREEN_ROWS=30 → hàng giữa = 14
    localparam LYRIC_ROW  = SCREEN_ROWS / 2; // tự động căn giữa

    // Cột bắt đầu lyric (căn giữa LINE_WIDTH ký tự trên SCREEN_COLS)
    // SCALE=2: (40 - 40) / 2 = 0 → lyric 40 ký tự vừa khít 40 cột
    // SCALE=1: (80 - 40) / 2 = 20
localparam LYRIC_COL_START = (SCREEN_COLS - LINE_WIDTH) / 2;
    localparam LYRIC_COL_END   = LYRIC_COL_START + LINE_WIDTH - 1;

    // Màu chữ lyric: vàng sáng
    localparam [3:0] R_FG = 4'hF;
    localparam [3:0] G_FG = 4'hE;
    localparam [3:0] B_FG = 4'h0;

    // Màu nền: đen
    localparam [3:0] R_BG = 4'h0;
    localparam [3:0] G_BG = 4'h0;
    localparam [3:0] B_BG = 4'h0;

    //==========================================================
    // TẦNG 0: TÍNH VỊ TRÍ KÝ TỰ (combinational)
    //
    // Phép chia cho CHAR_W, CHAR_H (lũy thừa 2 khi SCALE=2)
    // Quartus tối ưu thành shift → không tốn logic element thêm.
    // Nếu SCALE=3 (không phải lũy thừa 2), Quartus vẫn synthesis
    // được nhưng dùng thêm một vài LE cho adder.
    //==========================================================
    wire [6:0] char_col;       // cột ký tự trên màn
    wire [4:0] char_row_scr;   // hàng ký tự trên màn
    wire [2:0] font_x;         // pixel trong ký tự, chiều ngang (0..7)
    wire [3:0] font_y;         // pixel trong ký tự, chiều dọc  (0..15)

    // Chia tọa độ pixel cho kích thước ký tự đã scale
    // → ra vị trí ký tự trên lưới màn hình
    assign char_col     = pixel_x / CHAR_W;
    assign char_row_scr = pixel_y / CHAR_H;

    // Lấy phần dư sau khi chia SCALE để biết đang ở pixel nào
    // trong ô phóng to, rồi chia tiếp cho SCALE để map về font gốc
    assign font_x = (pixel_x % CHAR_W) / SCALE;   // 0..7
    assign font_y = (pixel_y % CHAR_H) / SCALE;   // 0..15

    // Kiểm tra pixel có nằm trong vùng lyric không
    wire in_lyric_row;
    wire in_lyric_col;
    wire in_lyric_zone;

    assign in_lyric_row  = (char_row_scr == LYRIC_ROW);
    assign in_lyric_col  = (char_col >= LYRIC_COL_START) &&
                           (char_col <= LYRIC_COL_END);
    assign in_lyric_zone = in_lyric_row && in_lyric_col;

    // Chỉ số ký tự trong dòng lyric (0..39)
    wire [5:0] char_idx_in_line;
    assign char_idx_in_line = char_col - LYRIC_COL_START[6:0];

    //==========================================================
    // LYRIC ROM
    //==========================================================
    wire [7:0] char_out;

    lyric_rom u_lyric_rom (
        .clk      (clk),
        .line_idx (lyric_line),
        .char_idx (char_idx_in_line),
        .char_out (char_out)
    );

    //==========================================================
    // FONT ROM
    //==========================================================

    // font_y delay 1 chu kỳ để đồng bộ với char_out (latency Lyric ROM)
    reg [3:0] font_y_d1;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) font_y_d1 <= 4'd0;
        else          font_y_d1 <= font_y;
    end

    wire [10:0] font_addr;
    assign font_addr = { char_out[6:0], font_y_d1 };

    wire [7:0] font_row_data;

    font_rom u_font_rom (
        .clk  (clk),
.addr (font_addr),
        .data (font_row_data)
    );

    //==========================================================
    // DELAY PIPELINE: font_x, video_on, in_lyric_zone
    // Cần delay 2 chu kỳ để đồng bộ với font_row_data
    //==========================================================

    // Delay 1
    reg [2:0] font_x_d1;
    reg       video_on_d1;
    reg       in_lyric_d1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            font_x_d1   <= 3'd0;
            video_on_d1 <= 1'b0;
            in_lyric_d1 <= 1'b0;
        end else begin
            font_x_d1   <= font_x;
            video_on_d1 <= video_on;
            in_lyric_d1 <= in_lyric_zone;
        end
    end

    // Delay 2
    reg [2:0] font_x_d2;
    reg       video_on_d2;
    reg       in_lyric_d2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            font_x_d2   <= 3'd0;
            video_on_d2 <= 1'b0;
            in_lyric_d2 <= 1'b0;
        end else begin
            font_x_d2   <= font_x_d1;
            video_on_d2 <= video_on_d1;
            in_lyric_d2 <= in_lyric_d1;
        end
    end

    //==========================================================
    // TẦNG 2: RENDER PIXEL
    // font_row_data[7] = pixel ngoài cùng bên trái
    // → bit cần chọn = font_row_data[7 - font_x_d2]
    //==========================================================
    wire font_pixel;
    assign font_pixel = font_row_data[3'd7 - font_x_d2];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
        else begin
            if (!video_on_d2) begin
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
            else if (in_lyric_d2 && font_pixel) begin
                // Pixel thuộc chữ lyric: màu chữ (vàng)
                vga_r <= R_FG;
                vga_g <= G_FG;
                vga_b <= B_FG;
            end
            else begin
                // Pixel nền
                vga_r <= R_BG;
                vga_g <= G_BG;
                vga_b <= B_BG;
            end
        end
    end

endmodule