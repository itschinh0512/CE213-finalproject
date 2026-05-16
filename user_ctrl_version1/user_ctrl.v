// user_ctrl.v
// User control block for karaoke volume and mute control.
//
// - SW[6:0] values 0..9 override the KEY step counter and select gain presets.
// - SW[6:0] values greater than 9 disable the SW override, so KEY0/KEY1 step.
// - KEY inputs are active-low DE2 push buttons.
// - No debounce filter is used. Buttons are only synchronized and edge-detected.
// - HEX1-HEX0 display the selected decimal volume level, 00..09.
// - Unused HEX and LEDR outputs are driven to their off states for kit testing.

module user_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] sw,
    input  wire [2:0] key_n,
    output wire [6:0] gain,
    output reg        mute,
    output wire [3:0] volume_level,
    output wire       sw_override,
    output wire [6:0] HEX1,
    output wire [6:0] HEX0,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [6:0] HEX6,
    output wire [6:0] HEX7,
    output wire [16:0] LEDR
);

    localparam MIN_LEVEL     = 4'd0;
    localparam MAX_LEVEL     = 4'd9;
    localparam DEFAULT_LEVEL = 4'd5;

    reg [2:0] key_meta;
    reg [2:0] key_sync;
    reg [2:0] key_sync_d;

    wire key0_press;
    wire key1_press;
    wire key2_press;

    reg [3:0] key_level;
    wire [6:0] key_gain;

    wire [3:0] sw_level;
    wire [6:0] sw_gain;
    wire       sw_valid;

    assign key0_press =  key_sync_d[0] & ~key_sync[0];
    assign key1_press =  key_sync_d[1] & ~key_sync[1];
    assign key2_press =  key_sync_d[2] & ~key_sync[2];

    sw_decoder u_sw_decoder (
        .sw(sw),
        .sw_level(sw_level),
        .sw_gain(sw_gain),
        .sw_valid(sw_valid)
    );

    assign sw_override  = sw_valid;
    assign gain         = sw_valid ? sw_gain : key_gain;
    assign volume_level = sw_valid ? sw_level : key_level;
    assign HEX2         = 7'b1111111;
    assign HEX3         = 7'b1111111;
    assign HEX4         = 7'b1111111;
    assign HEX5         = 7'b1111111;
    assign HEX6         = 7'b1111111;
    assign HEX7         = 7'b1111111;
    assign LEDR         = 17'b0;

    hex7seg u_hex0 (
        .digit(volume_level),
        .seg_n(HEX0)
    );

    hex7seg u_hex1 (
        .digit(4'd0),
        .seg_n(HEX1)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_meta   <= 3'b111;
            key_sync   <= 3'b111;
            key_sync_d <= 3'b111;
            key_level  <= DEFAULT_LEVEL;
            mute       <= 1'b0;
        end else begin
            key_meta   <= key_n;
            key_sync   <= key_meta;
            key_sync_d <= key_sync;

            if (key2_press)
                mute <= ~mute;

            if (key0_press && !key1_press && key_level < MAX_LEVEL)
                key_level <= key_level + 4'd1;
            else if (key1_press && !key0_press && key_level > MIN_LEVEL)
                key_level <= key_level - 4'd1;
        end
    end

    gain_lut u_key_gain_lut (
        .level(key_level),
        .gain(key_gain)
    );

endmodule

module hex7seg (
    input  wire [3:0] digit,
    output reg  [6:0] seg_n
);

    always @(*) begin
        case (digit)
            4'd0: seg_n = 7'b1000000;
            4'd1: seg_n = 7'b1111001;
            4'd2: seg_n = 7'b0100100;
            4'd3: seg_n = 7'b0110000;
            4'd4: seg_n = 7'b0011001;
            4'd5: seg_n = 7'b0010010;
            4'd6: seg_n = 7'b0000010;
            4'd7: seg_n = 7'b1111000;
            4'd8: seg_n = 7'b0000000;
            4'd9: seg_n = 7'b0010000;
            default: seg_n = 7'b1111111;
        endcase
    end

endmodule

module gain_lut (
    input  wire [3:0] level,
    output reg  [6:0] gain
);

    always @(*) begin
        case (level)
            4'd0: gain = 7'h30;
            4'd1: gain = 7'h38;
            4'd2: gain = 7'h40;
            4'd3: gain = 7'h48;
            4'd4: gain = 7'h50;
            4'd5: gain = 7'h58;
            4'd6: gain = 7'h60;
            4'd7: gain = 7'h68;
            4'd8: gain = 7'h70;
            4'd9: gain = 7'h7f;
            default: gain = 7'h58;
        endcase
    end

endmodule
