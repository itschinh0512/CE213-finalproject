//==============================================================
// LYRICS VGA TOP MODULE - BƯỚC 6
//
// Tích hợp toàn bộ các module:
//   vga_sync         → tạo tín hiệu VGA timing
//   lyric_controller → điều khiển chuyển dòng lyric
//   lyric_rom        → lưu nội dung lyric
//   font_rom         → lưu bitmap font 8x16
//   text_renderer    → render ký tự ra pixel màu
//
// Kết nối với DE2:
//   CLOCK_50         → clk
//   KEY[1]           → key_next (next lyric, active low)
//   KEY[2]           → key_prev (prev lyric, active low)
//   KEY[0]           → reset_n  (reset toàn hệ thống, active low)
//   SW[0]            → sw_auto  (0=manual, 1=auto timer)
//   VGA_HS, VGA_VS   → sync VGA monitor
//   VGA_R, VGA_G, VGA_B → màu pixel 4-bit
//   VGA_BLANK_N      → báo vùng hiển thị hợp lệ
//   VGA_SYNC_N       → composite sync (DE2 cần, thường nối GND)
//   VGA_CLK          → pixel clock cấp cho DAC VGA trên DE2
//==============================================================

module lyrics_vga_top (
    // Clock & Reset
    input  wire        CLOCK_50,
    input  wire        KEY0,       // reset_n (active low)
    input  wire        KEY1,       // next lyric (active low)
    input  wire        KEY2,       // prev lyric (active low)

    // Switch
    input  wire        SW0,        // 0=manual, 1=auto

    // VGA output
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    //==========================================================
    // NỘI BỘ
    //==========================================================
    wire        video_on;
    wire        pixel_tick;
    wire [9:0]  pixel_x;
    wire [9:0]  pixel_y;
    wire [4:0]  lyric_line;

    //==========================================================
    // VGA SYNC
    //==========================================================
    vga_sync u_vga_sync (
        .clk       (CLOCK_50),
        .reset_n   (KEY0),
        .VGA_HS    (VGA_HS),
        .VGA_VS    (VGA_VS),
        .video_on  (video_on),
        .pixel_tick(pixel_tick),
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y)
    );

    //==========================================================
    // LYRIC CONTROLLER
    //==========================================================
    lyric_controller u_lyric_ctrl (
        .clk        (CLOCK_50),
        .reset_n    (KEY0),
        .key_next   (KEY1),
        .key_prev   (KEY2),
        .sw_auto    (SW0),
        .lyric_line (lyric_line)
    );

    //==========================================================
    // TEXT RENDERER
    // (bên trong đã instantiate lyric_rom và font_rom)
    //==========================================================
    text_renderer u_text_renderer (
        .clk        (CLOCK_50),
        .reset_n    (KEY0),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .video_on   (video_on),
        .lyric_line (lyric_line),
        .vga_r      (VGA_R),
        .vga_g      (VGA_G),
        .vga_b      (VGA_B)
    );

    //==========================================================
    // TÍN HIỆU PHỤ CHO DAC VGA TRÊN DE2
    //
    // VGA_BLANK_N: HIGH khi pixel hợp lệ, LOW khi blanking
    //   => nối thẳng video_on (đã có pipeline delay trong
    //      text_renderer nên dùng video_on gốc ở đây là đủ,
    //      DAC chấp nhận 1-2 cycle slack)
    //
    // VGA_SYNC_N: composite sync, DE2 datasheet yêu cầu = 0
    //
    // VGA_CLK: pixel clock 25MHz cấp cho ADV7123 DAC
    //   => dùng pixel_tick (toggle FF 25MHz từ vga_sync)
    //   Cách chuẩn hơn là dùng PLL, nhưng pixel_tick đủ dùng
    //   cho mục đích đồ án
    //==========================================================
    assign VGA_BLANK_N = video_on;
    assign VGA_SYNC_N  = 1'b0;
    assign VGA_CLK     = pixel_tick;

endmodule