//==============================================================
// VGA SYNC MODULE - BƯỚC 1 (ĐÃ SỬA)
// Mục tiêu:
//   1. Tạo tín hiệu VGA_HS, VGA_VS chuẩn 640x480 @60Hz
//   2. Tạo pixel_x, pixel_y (chỉ hợp lệ khi video_on = 1)
//   3. Tạo video_on
//   4. pixel_tick là 1-cycle enable pulse tại 25MHz
//
// Sửa so với bản gốc:
//   [Fix 1] pixel_tick giờ là true 1-cycle pulse, không phải clock level
//   [Fix 2] pixel_x, pixel_y được mask = 0 khi nằm ngoài vùng hiển thị
//
// Board: DE2/DE2-115, CLOCK_50 = 50MHz
//==============================================================

module vga_sync (
    input  wire        clk,       // CLOCK_50 = 50MHz
    input  wire        reset_n,   // Active-low reset
    output wire        VGA_HS,    // Horizontal sync (active low)
    output wire        VGA_VS,    // Vertical sync   (active low)
    output wire        video_on,  // HIGH khi pixel thuộc vùng hiển thị
    output wire        pixel_tick,// 1-cycle enable pulse @ 25MHz
    output wire [9:0]  pixel_x,   // Tọa độ X (0..639), = 0 khi ngoài vùng
    output wire [9:0]  pixel_y    // Tọa độ Y (0..479), = 0 khi ngoài vùng
);

    //==========================================================
    // 1. TẠO PIXEL ENABLE PULSE 25MHz
    //    pixel_q toggle mỗi chu kỳ 50MHz
    //    pixel_tick = HIGH đúng 1 chu kỳ clk mỗi 2 chu kỳ clk
    //    => tương đương enable @ 25MHz, KHÔNG phải clock gating
    //==========================================================
    reg pixel_q;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pixel_q <= 1'b0;
        else
            pixel_q <= ~pixel_q;
    end

    // [Fix 1] Pulse HIGH chỉ khi pixel_q chuyển từ 1 -> 0
    // => đúng 1 chu kỳ clk mỗi 2 chu kỳ, an toàn với synthesis
    assign pixel_tick = (pixel_q == 1'b1);

    //==========================================================
    // 2. THÔNG SỐ VGA 640x480 @60Hz
    //    Pixel clock = 25.175MHz (dùng 25MHz cho DE2, lệch ~0.7%)
    //==========================================================

    // --- Horizontal timing (đơn vị: pixel) ---
    localparam H_DISPLAY = 640;   // Vùng hiển thị
    localparam H_FRONT   = 16;    // Front porch
    localparam H_SYNC    = 96;    // Sync pulse
    localparam H_BACK    = 48;    // Back porch
    localparam H_TOTAL   = 800;   // = 640+16+96+48

    // --- Vertical timing (đơn vị: dòng) ---
    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;   // = 480+10+2+33

    //==========================================================
    // 3. HORIZONTAL + VERTICAL COUNTER
    //    Chỉ tăng khi pixel_tick = 1 (mỗi 2 chu kỳ clk)
    //==========================================================
    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else if (pixel_tick) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    //==========================================================
    // 4. HSYNC & VSYNC (active low)
    //    Sync pulse bắt đầu sau Display + Front Porch
    //==========================================================
    assign VGA_HS = ~( (h_count >= H_DISPLAY + H_FRONT) &&
                       (h_count <  H_DISPLAY + H_FRONT + H_SYNC) );

    assign VGA_VS = ~( (v_count >= V_DISPLAY + V_FRONT) &&
                       (v_count <  V_DISPLAY + V_FRONT + V_SYNC) );

    //==========================================================
    // 5. VIDEO ON
    //    Chỉ HIGH khi đang trong vùng hiển thị thực sự
    //==========================================================
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    //==========================================================
    // 6. PIXEL COORDINATE
    //    [Fix 2] Trả về 0 khi nằm ngoài vùng hiển thị
    //    Đảm bảo text_renderer không render sai vị trí
    //==========================================================
    assign pixel_x = video_on ? h_count : 10'd0;
    assign pixel_y = video_on ? v_count : 10'd0;

endmodule