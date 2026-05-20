// volume_decoder.v
// Decode SW[3:0] into karaoke volume level 0..9.
// Values 10..15 are treated as invalid and fall back to DEFAULT_LEVEL.

module volume_decoder (
    input  wire [3:0] sw_volume,
    output reg  [3:0] volume_level,
    output reg        volume_valid
);

    localparam [3:0] DEFAULT_LEVEL = 4'd5;

    always @(*) begin
        if (sw_volume <= 4'd9) begin
            volume_level = sw_volume;
            volume_valid = 1'b1;
        end else begin
            volume_level = DEFAULT_LEVEL;
            volume_valid = 1'b0;
        end
    end

endmodule

