`timescale 1ns/1ps

module tb_vga_sync;

    reg clk;
    reg reset_n;

    wire VGA_HS;
    wire VGA_VS;
    wire video_on;
    wire pixel_tick;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    // Gọi module của bạn
    vga_sync uut (
        .clk(clk),
        .reset_n(reset_n),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .video_on(video_on),
        .pixel_tick(pixel_tick),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // Tạo clock 50MHz (chu kỳ 20ns)
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset_n = 0;

        #50;
        reset_n = 1;

        // chạy simulation
        #5_000_000;  // 5 ms là đủ thấy nhiều dòng

        $stop;
    end

endmodule