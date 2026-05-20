// =============================================================================
// i2s_transmitter.v - sửa lại
// Vấn đề cũ: lr_fall và bclk_rise có thể xảy ra cùng chu kỳ 50MHz
//            → first_bit chưa được set khi bclk_rise xử lý → mất MSB
// Sửa: tách riêng load data và shift ra 2 always block
//      dùng registered lrclk để load data trước 1 cycle
// =============================================================================



module i2s_transmitter (
    input  wire        clk,
    input  wire        reset,
    input  wire        bclk,
    input  wire        lrclk,
    input  wire [15:0] left_data,
    input  wire [15:0] right_data,
    output reg         sdata
);

// ── Đồng bộ hoá ──────────────────────────────────────────────────────────────
reg bclk_r1, bclk_r2, lr_r1, lr_r2, lr_r3;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        bclk_r1<=0; bclk_r2<=0;
        lr_r1  <=0; lr_r2  <=0; lr_r3<=0;
    end else begin
        bclk_r1 <= bclk;  bclk_r2 <= bclk_r1;
        lr_r1   <= lrclk; lr_r2   <= lr_r1; lr_r3 <= lr_r2;
    end
end

wire bclk_rise = ( bclk_r1 & ~bclk_r2);
// Dùng lr_r3/lr_r2 (trễ thêm 1 cycle) để tránh race condition
wire lr_fall   = (~lr_r2 &  lr_r3);  // 1→0: bắt đầu LEFT
wire lr_rise   = ( lr_r2 & ~lr_r3);  // 0→1: bắt đầu RIGHT

// ── Shift register phát bit ──────────────────────────────────────────────────
reg [15:0] tx_shift;
reg [4:0]  bit_cnt;
reg        first_bit;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx_shift  <= 0;
        bit_cnt   <= 0;
        sdata     <= 0;
        first_bit <= 0;
    end else begin

        // Load data khi bắt đầu frame mới
        if (lr_fall) begin
            tx_shift  <= left_data;
            bit_cnt   <= 0;
            first_bit <= 1;
        end else if (lr_rise) begin
            tx_shift  <= right_data;
            bit_cnt   <= 0;
            first_bit <= 1;
        end

        // Phát bit trên cạnh lên BCLK
        else if (bclk_rise) begin
            if (first_bit) begin
                sdata     <= tx_shift[15];  // MSB đầu tiên
                first_bit <= 0;
            end else if (bit_cnt < 16) begin
                sdata    <= tx_shift[15];
                tx_shift <= {tx_shift[14:0], 1'b0};
                bit_cnt  <= bit_cnt + 1;
            end else begin
                sdata <= 0;
            end
        end

    end
end

endmodule