`timescale 1ns / 1ps
// =============================================================================
// tb_audio_loopback.v  –  Testbench đơn giản cho module audio_loopback
//
// Mục tiêu kiểm tra:
//   LEDG[1] = bclk_cnt[23]   → BCLK đang chạy
//   LEDG[2] = lrck_cnt[15]   → LRCLK đang chạy
//   LEDG[3] = valid_cnt[15]  → ADC valid đang có
//   LEDG[4] = adc_left[15]   → Sign bit kênh trái
//   LEDG[5] = adc_right[15]  → Sign bit kênh phải
//
// Cách dùng (ModelSim / Questa / Icarus):
//   iverilog -o sim tb_audio_loopback.v audio_loopback.v audio_gain_apply.v \
//            audio_pll.v gain_control.v hex7seg.v i2c_av_config.v \
//            i2s_receiver.v i2s_transmitter.v
//   vvp sim
// =============================================================================

module tb_audio_loopback;

// ---------------------------------------------------------------------------
// 1. Tín hiệu kết nối với DUT
// ---------------------------------------------------------------------------
reg         CLOCK_50;
reg  [3:0]  KEY;
reg  [17:0] SW;
wire [7:0]  LEDG;
wire [6:0]  HEX0;
wire        I2C_SCLK;
wire        I2C_SDAT;
wire        AUD_XCK;

// BCLK và LRCLK: TB tự tạo để mô phỏng codec WM8731
//   BCLK  ≈ 3.072 MHz  → chu kỳ ≈ 326 ns
//   LRCLK ≈ 48 kHz     → mỗi frame = 64 BCLK = 32 bit trái + 32 bit phải
//   (ta dùng 16 bit/kênh như cấu hình I2S, bỏ 16 bit padding)
reg         AUD_BCLK;
reg         AUD_DACLRCK;
reg         AUD_ADCLRCK;
reg         AUD_ADCDAT;
wire        AUD_DACDAT;

// ---------------------------------------------------------------------------
// 2. Tham số thời gian
// ---------------------------------------------------------------------------
localparam CLK50_HALF  = 10;    // 10 ns → 50 MHz
localparam BCLK_HALF   = 163;   // 163 ns → ~3.07 MHz
localparam BITS_PER_CH = 16;    // 16 bit mỗi kênh theo cấu hình codec
localparam PADDING     = 16;    // padding 0 để đủ 32 bit/kênh (chuẩn I2S codec 32 BCLK/kênh)

// ---------------------------------------------------------------------------
// 3. Khởi tạo DUT
// ---------------------------------------------------------------------------
audio_loopback dut (
    .CLOCK_50    (CLOCK_50),
    .KEY         (KEY),
    .SW          (SW),
    .LEDG        (LEDG),
    .HEX0        (HEX0),
    .I2C_SCLK    (I2C_SCLK),
    .I2C_SDAT    (I2C_SDAT),
    .AUD_XCK     (AUD_XCK),
    .AUD_BCLK    (AUD_BCLK),
    .AUD_DACLRCK (AUD_DACLRCK),
    .AUD_ADCLRCK (AUD_ADCLRCK),
    .AUD_ADCDAT  (AUD_ADCDAT),
    .AUD_DACDAT  (AUD_DACDAT)
);

// ---------------------------------------------------------------------------
// 4. Clock 50 MHz
// ---------------------------------------------------------------------------
initial CLOCK_50 = 0;
always #CLK50_HALF CLOCK_50 = ~CLOCK_50;

// ---------------------------------------------------------------------------
// 5. BCLK ~3.07 MHz
// ---------------------------------------------------------------------------
initial AUD_BCLK = 0;
always #BCLK_HALF AUD_BCLK = ~AUD_BCLK;

// ---------------------------------------------------------------------------
// 6. Task: gửi 1 frame I2S (16-bit trái + 16-bit phải)
//    I2S standard: LRCLK thấp = kênh TRÁI, LRCLK cao = kênh PHẢI
//    MSB được truyền 1 BCLK sau cạnh LRCLK (delayed by 1)
// ---------------------------------------------------------------------------
task send_i2s_frame;
    input [15:0] left_sample;
    input [15:0] right_sample;
    integer i;
    begin
        // ── Kênh TRÁI (LRCLK = 0) ──────────────────────────────────────────
        // Cạnh xuống LRCLK → bắt đầu frame trái
        @(posedge AUD_BCLK); #1;
        AUD_ADCLRCK = 0;
        AUD_DACLRCK = 0;

        // 1 BCLK delay (I2S spec: MSB đến sau 1 chu kỳ)
        @(posedge AUD_BCLK); #1;

        // Gửi 16 bit trái, MSB trước
        for (i = 15; i >= 0; i = i - 1) begin
            AUD_ADCDAT = left_sample[i];
            @(posedge AUD_BCLK); #1;
        end

        // Padding 0 cho đủ 32 BCLK/kênh
        AUD_ADCDAT = 0;
        repeat (PADDING - 1) @(posedge AUD_BCLK);
        #1;

        // ── Kênh PHẢI (LRCLK = 1) ─────────────────────────────────────────
        AUD_ADCLRCK = 1;
        AUD_DACLRCK = 1;

        @(posedge AUD_BCLK); #1;

        for (i = 15; i >= 0; i = i - 1) begin
            AUD_ADCDAT = right_sample[i];
            @(posedge AUD_BCLK); #1;
        end

        AUD_ADCDAT = 0;
        repeat (PADDING - 1) @(posedge AUD_BCLK);
        #1;
    end
endtask

// ---------------------------------------------------------------------------
// 7. Task: kiểm tra LED và in kết quả
// ---------------------------------------------------------------------------
task check_leds;
    input [15:0] exp_left;
    input [15:0] exp_right;
    input [63:0] test_name;  // không dùng string để tương thích rộng hơn
    begin
        $display("──────────────────────────────────────────────");
        $display("LEDG[1] BCLK   running : %b  (mong đợi: 0 hoặc 1 nhấp nháy)", LEDG[1]);
        $display("LEDG[2] LRCLK  running : %b  (mong đợi: 0 hoặc 1 nhấp nháy)", LEDG[2]);
        $display("LEDG[3] Valid  pulse   : %b  (mong đợi: 0 hoặc 1 nhấp nháy)", LEDG[3]);
        $display("LEDG[4] ADC Left  sign : %b  (mong đợi: %b)", LEDG[4], exp_left[15]);
        $display("LEDG[5] ADC Right sign : %b  (mong đợi: %b)", LEDG[5], exp_right[15]);
        if (LEDG[4] !== exp_left[15])
            $display("  [FAIL] LEDG[4] sign bit trái sai!");
        else
            $display("  [PASS] LEDG[4] sign bit trái đúng.");
        if (LEDG[5] !== exp_right[15])
            $display("  [FAIL] LEDG[5] sign bit phải sai!");
        else
            $display("  [PASS] LEDG[5] sign bit phải đúng.");
    end
endtask

// ---------------------------------------------------------------------------
// 8. Luồng test chính
// ---------------------------------------------------------------------------
initial begin
    // Dump waveform (dùng với GTKWave)
    $dumpfile("tb_audio_loopback.vcd");
    $dumpvars(0, tb_audio_loopback);

    // ── Khởi tạo ────────────────────────────────────────────────────────────
    KEY         = 4'b1111;   // active-low → tất cả nhả
    SW          = 18'd1;     // SW[0]=1 → Unmute
    AUD_ADCDAT  = 0;
    AUD_ADCLRCK = 0;
    AUD_DACLRCK = 0;

    // ── Reset ────────────────────────────────────────────────────────────────
    $display("\n=== RESET ===");
    KEY[0] = 0;              // kéo KEY[0] xuống → reset = 1
    repeat (10) @(posedge CLOCK_50);
    KEY[0] = 1;              // nhả KEY[0] → reset = 0
    repeat (20) @(posedge CLOCK_50);

    // ── TEST 1: Tín hiệu dương kênh trái, âm kênh phải ─────────────────────
    $display("\n=== TEST 1: Left=+5000 (dương), Right=-3000 (âm) ===");
    $display("    LEDG[4] sign trái mong đợi: 0 (dương)");
    $display("    LEDG[5] sign phải mong đợi: 1 (âm)");
    // Gửi vài frame để bộ đếm valid_cnt[15] bắt đầu nhấp nháy
    repeat (5) send_i2s_frame(16'd5000, -16'd3000);
    repeat (5) @(posedge CLOCK_50);
    check_leds(16'd5000, -16'd3000, "TEST1");

    // ── TEST 2: Tín hiệu âm kênh trái, dương kênh phải ─────────────────────
    $display("\n=== TEST 2: Left=-8000 (âm), Right=+12000 (dương) ===");
    $display("    LEDG[4] sign trái mong đợi: 1 (âm)");
    $display("    LEDG[5] sign phải mong đợi: 0 (dương)");
    repeat (5) send_i2s_frame(-16'd8000, 16'd12000);
    repeat (5) @(posedge CLOCK_50);
    check_leds(-16'd8000, 16'd12000, "TEST2");

    // ── TEST 3: Cả hai kênh âm (signal âm = tiếng to ở nửa chu kỳ âm) ─────
    $display("\n=== TEST 3: Left=-1, Right=-32768 (full negative) ===");
    $display("    LEDG[4] sign trái mong đợi: 1");
    $display("    LEDG[5] sign phải mong đợi: 1");
    repeat (5) send_i2s_frame(16'hFFFF, 16'h8000);
    repeat (5) @(posedge CLOCK_50);
    check_leds(16'hFFFF, 16'h8000, "TEST3");

    // ── TEST 4: Cả hai kênh dương ────────────────────────────────────────────
    $display("\n=== TEST 4: Left=+32767, Right=+1 (full positive) ===");
    $display("    LEDG[4] sign trái mong đợi: 0");
    $display("    LEDG[5] sign phải mong đợi: 0");
    repeat (5) send_i2s_frame(16'h7FFF, 16'h0001);
    repeat (5) @(posedge CLOCK_50);
    check_leds(16'h7FFF, 16'h0001, "TEST4");

    // ── TEST 5: Mute SW[0]=0 ─────────────────────────────────────────────────
    $display("\n=== TEST 5: Mute (SW[0]=0) ===");
    $display("    LEDG[0] mong đợi: 1 (đang mute)");
    SW[0] = 0;  // Mute
    repeat (5) @(posedge CLOCK_50);
    $display("    LEDG[0] MUTE flag: %b  (mong đợi: 1)", LEDG[0]);
    if (LEDG[0] === 1'b1)
        $display("    [PASS] Mute flag đúng.");
    else
        $display("    [FAIL] Mute flag sai!");

    // ── TEST 6: Unmute lại ───────────────────────────────────────────────────
    $display("\n=== TEST 6: Unmute (SW[0]=1) ===");
    SW[0] = 1;
    repeat (5) @(posedge CLOCK_50);
    $display("    LEDG[0] MUTE flag: %b  (mong đợi: 0)", LEDG[0]);
    if (LEDG[0] === 1'b0)
        $display("    [PASS] Unmute đúng.");
    else
        $display("    [FAIL] Unmute sai!");

    // ── TEST 7: Tăng gain KEY[2] ─────────────────────────────────────────────
    $display("\n=== TEST 7: Nhấn KEY[2] tăng gain từ x1 lên x2 ===");
    $display("    HEX0 ban đầu (gain=1): %b", HEX0);
    KEY[2] = 0;  // nhấn
    repeat (20) @(posedge CLOCK_50);
    KEY[2] = 1;  // nhả
    repeat (10) @(posedge CLOCK_50);
    $display("    HEX0 sau nhấn KEY[2] (gain=2): %b", HEX0);

    // ── TEST 8: Reset gain KEY[1] ────────────────────────────────────────────
    $display("\n=== TEST 8: Nhấn KEY[1] reset gain về x1 ===");
    KEY[1] = 0;
    repeat (20) @(posedge CLOCK_50);
    KEY[1] = 1;
    repeat (10) @(posedge CLOCK_50);
    $display("    HEX0 sau reset gain (gain=1): %b  (mong đợi 7'b1111001)", HEX0);
    if (HEX0 === 7'b1111001)
        $display("    [PASS] HEX0 hiển thị đúng số 1.");
    else
        $display("    [FAIL] HEX0 sai!");

    // ── Kiểm tra BCLK/LRCLK counter đã chạy ─────────────────────────────────
    $display("\n=== Trạng thái LED clock sau toàn bộ test ===");
    $display("    LEDG[1] (BCLK  counter bit23): %b", LEDG[1]);
    $display("    LEDG[2] (LRCLK counter bit15): %b", LEDG[2]);
    $display("    LEDG[3] (Valid counter bit15): %b", LEDG[3]);
    $display("    (Các LED trên sẽ nhấp nháy trên phần cứng; trong sim chỉ");
    $display("     thấy 1 thời điểm - quan sát waveform để xác nhận)");

    $display("\n=== SIMULATION DONE ===\n");
    $finish;
end

// ---------------------------------------------------------------------------
// 9. Timeout toàn cục (tránh chạy vô tận nếu có bug)
// ---------------------------------------------------------------------------
initial begin
    #50_000_000;  // 50 ms mô phỏng
    $display("[TIMEOUT] Simulation timed out!");
    $finish;
end

endmodule