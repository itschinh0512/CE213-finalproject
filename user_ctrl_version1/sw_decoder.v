// sw_decoder.v
// Decodes SW[6:0] into a coarse 7-bit audio-codec gain preset.
// SW values 0..9 select a preset. Other values make sw_valid low so
// the top-level priority mux falls back to the KEY step counter.

module sw_decoder (
    input  wire [6:0] sw,
    output reg  [3:0] sw_level,
    output reg  [6:0] sw_gain,
    output reg        sw_valid
);

    always @(*) begin
        sw_level = 4'd0;
        sw_gain  = 7'h30;
        sw_valid = (sw <= 7'd9);

        case (sw[3:0])
            4'd0: sw_gain = 7'h30;
            4'd1: sw_gain = 7'h38;
            4'd2: sw_gain = 7'h40;
            4'd3: sw_gain = 7'h48;
            4'd4: sw_gain = 7'h50;
            4'd5: sw_gain = 7'h58;
            4'd6: sw_gain = 7'h60;
            4'd7: sw_gain = 7'h68;
            4'd8: sw_gain = 7'h70;
            4'd9: sw_gain = 7'h7f;
            default: sw_gain = 7'h30;
        endcase

        if (sw_valid)
            sw_level = sw[3:0];
    end

endmodule
