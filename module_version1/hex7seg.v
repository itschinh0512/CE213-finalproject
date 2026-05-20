// hex7seg.v
// Active-low seven-segment decoder for DE2 HEX displays.

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

