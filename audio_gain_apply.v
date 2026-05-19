module audio_gain_apply (
    input  wire signed [15:0] in_left,
    input  wire signed [15:0] in_right,
    input  wire [2:0]         gain_level,

    output wire signed [15:0] out_left,
    output wire signed [15:0] out_right
);

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

function signed [31:0] apply_gain;
    input signed [15:0] sample;
    input [2:0] level;
    reg signed [31:0] ext;
    begin
        ext = {{16{sample[15]}}, sample};

        case (level)
            3'd0: apply_gain = ext;        // x1
            3'd1: apply_gain = ext <<< 1;  // x2
            3'd2: apply_gain = ext <<< 2;  // x4
            3'd3: apply_gain = ext <<< 3;  // x8
            3'd4: apply_gain = ext <<< 4;  // x16
            3'd5: apply_gain = ext <<< 5;  // x32
            3'd6: apply_gain = ext <<< 6;  // x64
            3'd7: apply_gain = ext <<< 7;  // x128
            default: apply_gain = ext;
        endcase
    end
endfunction

assign out_left  = clamp16(apply_gain(in_left,  gain_level));
assign out_right = clamp16(apply_gain(in_right, gain_level));

endmodule