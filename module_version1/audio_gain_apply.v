// audio_gain_apply.v
// Apply digital karaoke volume to signed 16-bit stereo samples.
//
// Volume mapping uses Q3 fixed-point scale numerators:
//   0: 0x, 1: 0.125x, 2: 0.25x, 3: 0.5x, 4: 0.75x,
//   5: 1x, 6: 1.5x, 7: 2x, 8: 3x, 9: 4x.

module audio_gain_apply (
    input  wire signed [15:0] in_left,
    input  wire signed [15:0] in_right,
    input  wire [3:0]         volume_level,

    output wire signed [15:0] out_left,
    output wire signed [15:0] out_right
);

    function [5:0] gain_num;
        input [3:0] level;
        begin
            case (level)
                4'd0: gain_num = 6'd0;
                4'd1: gain_num = 6'd1;
                4'd2: gain_num = 6'd2;
                4'd3: gain_num = 6'd4;
                4'd4: gain_num = 6'd6;
                4'd5: gain_num = 6'd8;
                4'd6: gain_num = 6'd12;
                4'd7: gain_num = 6'd16;
                4'd8: gain_num = 6'd24;
                4'd9: gain_num = 6'd32;
                default: gain_num = 6'd8;
            endcase
        end
    endfunction

    function signed [15:0] clamp16;
        input signed [31:0] x;
        begin
            if (x > 32'sd32767)
                clamp16 = 16'sd32767;
            else if (x < -32'sd32768)
                clamp16 = -16'sd32768;
            else
                clamp16 = x[15:0];
        end
    endfunction

    function signed [15:0] apply_volume;
        input signed [15:0] sample;
        input [3:0] level;
        reg signed [31:0] product;
        begin
            product = $signed(sample) * $signed({1'b0, gain_num(level)});
            apply_volume = clamp16(product >>> 3);
        end
    endfunction

    assign out_left  = apply_volume(in_left, volume_level);
    assign out_right = apply_volume(in_right, volume_level);

endmodule

