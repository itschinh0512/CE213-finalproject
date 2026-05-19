module i2c_av_config (
    input  wire  iCLK,
    input  wire  iRST_N,
    output reg   I2C_SCLK,
    inout  wire  I2C_SDAT
);

localparam DEVICE_ADDR = 8'h34;
localparam NUM_REGS = 11;

reg [15:0] rom [0:NUM_REGS-1];
initial begin
    rom[0]  = 16'h1E00; // Reset
    rom[1]  = 16'h0017; // Left line-in 0 dB, unmute
    rom[2]  = 16'h0217; // Right line-in 0 dB, unmute
    rom[3]  = 16'h047F; // Left headphone max
    rom[4]  = 16'h067F; // Right headphone max
    rom[5]  = 16'h0812; // R4: DACSEL=1, BYPASS=0, MUTEMIC=1
    rom[6]  = 16'h0A00; // R5: DAC soft mute off, ADC HPF on
    rom[7]  = 16'h0C00; // R6: power all on
    rom[8]  = 16'h0E42; // R7: master mode, I2S, 16-bit
    rom[9]  = 16'h1000; // R8: normal mode, 48k with 18.432MHz MCLK
    rom[10] = 16'h1201; // Active
end

reg [8:0] cnt; reg tick;
always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin cnt <= 0; tick <= 0; end
    else begin
        tick <= 0;
        if (cnt == 9'd249) begin cnt <= 0; tick <= 1; end
        else cnt <= cnt + 1'b1;
    end
end

reg [19:0] dly; reg dly_done;
always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin dly <= 0; dly_done <= 0; end
    else if (!dly_done) begin
        if (dly == 20'd999999) dly_done <= 1;
        else dly <= dly + 1'b1;
    end
end

localparam S_IDLE=0,S_START1=1,S_START2=2,S_SEND=3,S_ACK=4,S_STOP1=5,S_STOP2=6,S_NEXT=7,S_DONE=8;
reg [3:0] state, reg_idx; reg [1:0] byte_idx; reg [2:0] bit_idx; reg [7:0] tx_byte; reg sda_out, sda_oe, scl_ph;
assign I2C_SDAT = sda_oe ? sda_out : 1'bz;

always @(posedge iCLK or negedge iRST_N) begin
    if (!iRST_N) begin
        state<=S_IDLE; reg_idx<=0; byte_idx<=0; bit_idx<=7; tx_byte<=0;
        I2C_SCLK<=1; sda_out<=1; sda_oe<=1; scl_ph<=0;
    end else if (tick) begin
        case (state)
        S_IDLE: begin I2C_SCLK<=1; sda_out<=1; sda_oe<=1; if (dly_done && reg_idx<NUM_REGS) state<=S_START1; end
        S_START1: begin I2C_SCLK<=1; sda_out<=0; sda_oe<=1; state<=S_START2; end
        S_START2: begin I2C_SCLK<=0; byte_idx<=0; bit_idx<=7; scl_ph<=0; tx_byte<=DEVICE_ADDR; state<=S_SEND; end
        S_SEND: begin
            scl_ph <= ~scl_ph;
            if (!scl_ph) begin I2C_SCLK<=0; sda_out<=tx_byte[7]; sda_oe<=1; end
            else begin
                I2C_SCLK<=1;
                if (bit_idx==0) begin state<=S_ACK; scl_ph<=0; end
                else begin tx_byte<={tx_byte[6:0],1'b0}; bit_idx<=bit_idx-1'b1; end
            end
        end
        S_ACK: begin
            scl_ph <= ~scl_ph;
            if (!scl_ph) begin I2C_SCLK<=0; sda_oe<=0; end
            else begin
                I2C_SCLK<=1;
                if (byte_idx==2) begin state<=S_STOP1; scl_ph<=0; end
                else begin
                    byte_idx<=byte_idx+1'b1; bit_idx<=7; scl_ph<=0; sda_oe<=1;
                    case(byte_idx+1'b1)
                        //2'd1: tx_byte<=rom[reg_idx][15:8];
                        //2'd2: tx_byte<=rom[reg_idx][7:0];
								2'd1: tx_byte <= {rom[reg_idx][15:9], rom[reg_idx][8]};
								2'd2: tx_byte <= rom[reg_idx][7:0];
                        default: tx_byte<=8'h00;
                    endcase
                    state<=S_SEND;
                end
            end
        end
        S_STOP1: begin I2C_SCLK<=0; sda_out<=0; sda_oe<=1; state<=S_STOP2; end
        S_STOP2: begin I2C_SCLK<=1; sda_out<=0; state<=S_NEXT; end
        S_NEXT: begin sda_out<=1; if (reg_idx<NUM_REGS-1) begin reg_idx<=reg_idx+1'b1; state<=S_IDLE; end else state<=S_DONE; end
        S_DONE: begin I2C_SCLK<=1; sda_out<=1; sda_oe<=1; end
        default: state<=S_IDLE;
        endcase
    end
end
endmodule