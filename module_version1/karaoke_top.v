// karaoke_top.v
// Integrated DE2 karaoke machine:
//   - WM8731 audio loopback with digital volume and mute
//   - VGA lyrics display
//   - Unified controls
//
// Controls:
//   KEY[3]   = global reset, active low
//   KEY[2]   = mute toggle, active low press
//   KEY[1]   = lyric next, active low press
//   KEY[0]   = lyric previous, active low press
//   SW[3:0]  = volume 0..9, values 10..15 fall back to 5
//   SW[17]   = lyric mode, 0 manual, 1 auto

module karaoke_top (
    input  wire        CLOCK_50,
    input  wire        CLOCK_27,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,

    output wire [17:0] LEDR,
    output wire [8:0]  LEDG,

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7,

    output wire        I2C_SCLK,
    inout  wire        I2C_SDAT,

    output wire        AUD_XCK,
    input  wire        AUD_BCLK,
    input  wire        AUD_DACLRCK,
    input  wire        AUD_ADCLRCK,
    input  wire        AUD_ADCDAT,
    output wire        AUD_DACDAT,

    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [9:0]  VGA_R,
    output wire [9:0]  VGA_G,
    output wire [9:0]  VGA_B,
    output wire        VGA_BLANK,
    output wire        VGA_SYNC,
    output wire        VGA_CLK
);

    wire global_reset_n = KEY[3];

    // ---------------------------------------------------------------------
    // Audio codec clock. This compile-safe version divides CLOCK_50 by 4
    // to produce a 12.5 MHz AUD_XCK without using a Cyclone II altpll.
    // ---------------------------------------------------------------------
    wire audio_pll_locked;

    audio_pll u_audio_pll (
        .areset (~global_reset_n),
        .inclk0 (CLOCK_50),
        .c0     (AUD_XCK),
        .locked (audio_pll_locked)
    );

    wire audio_reset_n = global_reset_n & audio_pll_locked;
    wire audio_reset   = ~audio_reset_n;

    i2c_av_config u_i2c_cfg (
        .iCLK     (CLOCK_50),
        .iRST_N   (audio_reset_n),
        .I2C_SCLK (I2C_SCLK),
        .I2C_SDAT (I2C_SDAT)
    );

    // ---------------------------------------------------------------------
    // Volume and mute controls
    // ---------------------------------------------------------------------
    wire [3:0] volume_level;
    wire       volume_valid;

    volume_decoder u_volume_decoder (
        .sw_volume    (SW[3:0]),
        .volume_level (volume_level),
        .volume_valid (volume_valid)
    );

    reg key2_meta;
    reg key2_sync;
    reg key2_sync_d;
    reg mute;

    wire key2_press = key2_sync_d & ~key2_sync;

    always @(posedge CLOCK_50 or negedge global_reset_n) begin
        if (!global_reset_n) begin
            key2_meta   <= 1'b1;
            key2_sync   <= 1'b1;
            key2_sync_d <= 1'b1;
            mute        <= 1'b0;
        end else begin
            key2_meta   <= KEY[2];
            key2_sync   <= key2_meta;
            key2_sync_d <= key2_sync;

            if (key2_press)
                mute <= ~mute;
        end
    end

    // ---------------------------------------------------------------------
    // Audio ADC -> digital gain/mute -> DAC
    // ---------------------------------------------------------------------
    wire signed [15:0] adc_left;
    wire signed [15:0] adc_right;
    wire signed [15:0] gained_left;
    wire signed [15:0] gained_right;
    wire               adc_valid;

    i2s_receiver u_i2s_rx (
        .clk        (CLOCK_50),
        .reset      (audio_reset),
        .bclk       (AUD_BCLK),
        .lrclk      (AUD_ADCLRCK),
        .sdata      (AUD_ADCDAT),
        .left_data  (adc_left),
        .right_data (adc_right),
        .data_valid (adc_valid)
    );

    audio_gain_apply u_gain_apply (
        .in_left      (adc_left),
        .in_right     (adc_right),
        .volume_level (volume_level),
        .out_left     (gained_left),
        .out_right    (gained_right)
    );

    i2s_transmitter u_i2s_tx (
        .clk        (CLOCK_50),
        .reset      (audio_reset),
        .bclk       (AUD_BCLK),
        .lrclk      (AUD_DACLRCK),
        .left_data  (mute ? 16'sd0 : gained_left),
        .right_data (mute ? 16'sd0 : gained_right),
        .sdata      (AUD_DACDAT)
    );

    // ---------------------------------------------------------------------
    // VGA lyrics pipeline
    // ---------------------------------------------------------------------
    wire        video_on;
    wire        pixel_tick;
    wire [9:0]  pixel_x;
    wire [9:0]  pixel_y;
    wire [4:0]  lyric_line;
    wire [3:0]  vga_r_4;
    wire [3:0]  vga_g_4;
    wire [3:0]  vga_b_4;

    vga_sync u_vga_sync (
        .clk        (CLOCK_50),
        .reset_n    (global_reset_n),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .video_on   (video_on),
        .pixel_tick (pixel_tick),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y)
    );

    lyric_controller u_lyric_controller (
        .clk        (CLOCK_50),
        .reset_n    (global_reset_n),
        .key_next   (KEY[1]),
        .key_prev   (KEY[0]),
        .sw_auto    (SW[17]),
        .lyric_line (lyric_line)
    );

    text_renderer u_text_renderer (
        .clk        (CLOCK_50),
        .reset_n    (global_reset_n),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .video_on   (video_on),
        .lyric_line (lyric_line),
        .vga_r      (vga_r_4),
        .vga_g      (vga_g_4),
        .vga_b      (vga_b_4)
    );

    assign VGA_R     = {vga_r_4, 6'b000000};
    assign VGA_G     = {vga_g_4, 6'b000000};
    assign VGA_B     = {vga_b_4, 6'b000000};
    assign VGA_BLANK = video_on;
    assign VGA_SYNC  = 1'b0;
    assign VGA_CLK   = pixel_tick;

    // ---------------------------------------------------------------------
    // Displays and debug LEDs
    // ---------------------------------------------------------------------
    hex7seg u_hex0 (
        .digit (volume_level),
        .seg_n (HEX0)
    );

    hex7seg u_hex1 (
        .digit (4'd0),
        .seg_n (HEX1)
    );

    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;
    assign HEX6 = 7'b1111111;
    assign HEX7 = 7'b1111111;

    reg [25:0] bclk_cnt;
    reg [25:0] lrck_cnt;
    reg [23:0] valid_cnt;

    always @(posedge AUD_BCLK or posedge audio_reset) begin
        if (audio_reset)
            bclk_cnt <= 26'd0;
        else
            bclk_cnt <= bclk_cnt + 1'b1;
    end

    always @(posedge AUD_DACLRCK or posedge audio_reset) begin
        if (audio_reset)
            lrck_cnt <= 26'd0;
        else
            lrck_cnt <= lrck_cnt + 1'b1;
    end

    always @(posedge CLOCK_50 or posedge audio_reset) begin
        if (audio_reset)
            valid_cnt <= 24'd0;
        else if (adc_valid)
            valid_cnt <= valid_cnt + 1'b1;
    end

    assign LEDG[0] = mute;
    assign LEDG[1] = bclk_cnt[23];
    assign LEDG[2] = lrck_cnt[15];
    assign LEDG[3] = valid_cnt[15];
    assign LEDG[4] = adc_left[15];
    assign LEDG[5] = adc_right[15];
    assign LEDG[6] = audio_pll_locked;
    assign LEDG[7] = volume_valid;
    assign LEDG[8] = SW[17];

    assign LEDR[3:0]  = volume_level;
    assign LEDR[4]    = ~volume_valid;
    assign LEDR[5]    = mute;
    assign LEDR[10:6] = lyric_line;
    assign LEDR[16:11] = 6'b000000;
    assign LEDR[17]   = SW[17];

endmodule
