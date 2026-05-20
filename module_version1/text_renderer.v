//==============================================================
// TEXT RENDERER MODULE - BƯỚC 4
//
// Chức năng:
//   Nhận pixel_x, pixel_y từ vga_sync.
//   Tính vị trí ký tự và vị trí pixel trong ký tự.
//   Query Lyric ROM → Font ROM theo pipeline 2 tầng.
//   Xuất màu RGB 4-bit cho từng pixel.
//
// Pipeline (mỗi tầng = 1 chu kỳ clk):
//   Tầng 0 (combinational): tính char_col, char_row, font_x, font_y
//                           → addr cho Lyric ROM
//   Tầng 1 (posedge clk)  : Lyric ROM registered read → char_out
//                           → addr cho Font ROM
//   Tầng 2 (posedge clk)  : Font ROM registered read → font_row_data
//                           → chọn bit font_x_d2
//                           → xuất RGB
//
// Delay compensation:
//   pixel_x, pixel_y, video_on được delay 2 chu kỳ song song
//   để đồng bộ với font_row_data ở tầng 2.
//
// Thông số font: 8x16 (8 pixel rộng, 16 pixel cao)
// Thông số màn: 640x480, tối đa 80 cột x 30 hàng ký tự
// Lyric hiển thị: 1 dòng lyric tại hàng ký tự LYRIC_ROW (mặc định = 14)
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
    localparam FONT_W     = 8;          // pixel/ký tự theo chiều ngang
    localparam FONT_H     = 16;         // pixel/ký tự theo chiều dọc
    localparam LINE_WIDTH = 40;         // ký tự/dòng lyric (khớp lyric_rom)

    // Hàng ký tự nào trên màn hình dùng để hiển thị lyric
    // Màn 480px / 16px = 30 hàng ký tự (0..29)
    // LYRIC_ROW = 14 → giữa màn hình (hàng pixel 224..239)
    localparam LYRIC_ROW  = 14;

    // Cột bắt đầu của lyric (căn giữa 40 ký tự trên 80 cột)
    // (80 - 40) / 2 = 20
    localparam LYRIC_COL_START = 20;
    localparam LYRIC_COL_END   = LYRIC_COL_START + LINE_WIDTH - 1; // 59

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
    //==========================================================
    wire [6:0] char_col;      // cột ký tự trên màn (0..79)
    wire [4:0] char_row_scr;  // hàng ký tự trên màn (0..29)
    wire [2:0] font_x;        // pixel trong ký tự, chiều ngang (0..7)
    wire [3:0] font_y;        // pixel trong ký tự, chiều dọc  (0..15)

    assign char_col     = pixel_x[9:3];       // pixel_x / 8  (dịch phải 3 bit)
    assign char_row_scr = pixel_y[9:4];       // pixel_y / 16 (dịch phải 4 bit)
    assign font_x       = pixel_x[2:0];       // pixel_x % 8  (3 bit thấp)
    assign font_y       = pixel_y[3:0];       // pixel_y % 16 (4 bit thấp)

    // Kiểm tra pixel có nằm trong vùng lyric không
    // (đúng hàng ký tự và đúng cột ký tự)
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
    // LYRIC ROM (instantiate)
    // Query: line_idx = lyric_line, char_idx = char_idx_in_line
    // Output: char_out (registered, latency = 1 clk)
    //==========================================================
    wire [7:0] char_out;

    lyric_rom u_lyric_rom (
        .clk      (clk),
        .line_idx (lyric_line),
        .char_idx (char_idx_in_line),
        .char_out (char_out)
    );

    //==========================================================
    // FONT ROM (instantiate)
    // Query: addr = {char_out[6:0], font_y_d1}
    // Output: font_row_data (registered, latency = 1 clk)
    //==========================================================

    // font_y cần được delay 1 chu kỳ để dùng làm addr Font ROM
    // cùng lúc char_out ra (tầng 1)
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
    // DELAY PIPELINE cho pixel_x, font_x, video_on, in_lyric_zone
    // Mỗi tín hiệu cần delay 2 chu kỳ để đồng bộ với font_row_data
    //==========================================================

    // --- Delay 1 chu kỳ ---
    reg [2:0] font_x_d1;
    reg       video_on_d1;
    reg       in_lyric_d1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            font_x_d1    <= 3'd0;
            video_on_d1  <= 1'b0;
            in_lyric_d1  <= 1'b0;
        end else begin
            font_x_d1    <= font_x;
            video_on_d1  <= video_on;
            in_lyric_d1  <= in_lyric_zone;
        end
    end

    // --- Delay 2 chu kỳ ---
    reg [2:0] font_x_d2;
    reg       video_on_d2;
    reg       in_lyric_d2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            font_x_d2    <= 3'd0;
            video_on_d2  <= 1'b0;
            in_lyric_d2  <= 1'b0;
        end else begin
            font_x_d2    <= font_x_d1;
            video_on_d2  <= video_on_d1;
            in_lyric_d2  <= in_lyric_d1;
        end
    end

    //==========================================================
    // TẦNG 2: RENDER PIXEL
    // font_row_data đã sẵn sàng, dùng font_x_d2 để chọn bit
    //
    // font_row_data là 8 bit, bit[7] = pixel ngoài cùng bên trái
    // => bit cần chọn = font_row_data[7 - font_x_d2]
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
                // Ngoài vùng hiển thị: xuất đen tuyệt đối
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
            else if (in_lyric_d2 && font_pixel) begin
                // Pixel thuộc chữ lyric: màu chữ
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