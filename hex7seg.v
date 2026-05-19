// =============================================================================
// hex7seg.v
// Giải mã số 1..8 ra HEX 7-đoạn (active-low trên DE2)
// =============================================================================
module hex7seg (
    input  wire [3:0] num,      // số 0..8
    output reg  [6:0] hex       // 7 đoạn, active-low (0=sáng)
);
//        _
//       |_|   segments: 6=top, 5=top-left, 4=top-right,
//       |_|              3=middle, 2=bot-left, 1=bot-right, 0=bottom
//
// bit:  6 5 4 3 2 1 0
always @(*) begin
    case (num)
        4'd1: hex = 7'b1111001;  // 1
        4'd2: hex = 7'b0100100;  // 2
        4'd3: hex = 7'b0110000;  // 3
        4'd4: hex = 7'b0011001;  // 4
        4'd5: hex = 7'b0010010;  // 5
        4'd6: hex = 7'b0000010;  // 6
        4'd7: hex = 7'b1111000;  // 7
        4'd8: hex = 7'b0000000;  // 8
        default: hex = 7'b1111111; // tắt hết
    endcase
end
endmodule