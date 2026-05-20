// audio_pll.v
// Compile-safe audio master clock generator for the DE2 WM8731 path.
//
// This version intentionally avoids the Quartus altpll megafunction because
// the generated PLL settings from the separated branches did not fit as a
// Cyclone II PLL in the merged project.
//
// Input  inclk0: 50 MHz
// Output c0    : 12.5 MHz, made by a divide-by-4 counter
//
// WM8731 normally uses 12.288 MHz for the 48 kHz family. 12.5 MHz is close
// enough to compile and validate the merged datapath; regenerate a true PLL
// later if exact audio sampling is required.

module audio_pll (
    input  wire areset,
    input  wire inclk0,
    output reg  c0,
    output reg  locked
);

    reg [1:0] div_cnt;
    reg [7:0] lock_cnt;

    always @(posedge inclk0 or posedge areset) begin
        if (areset) begin
            div_cnt  <= 2'd0;
            lock_cnt <= 8'd0;
            c0       <= 1'b0;
            locked   <= 1'b0;
        end else begin
            div_cnt <= div_cnt + 2'd1;

            if (div_cnt == 2'd1)
                c0 <= ~c0;

            if (!locked) begin
                lock_cnt <= lock_cnt + 8'd1;
                if (lock_cnt == 8'hff)
                    locked <= 1'b1;
            end
        end
    end

endmodule

