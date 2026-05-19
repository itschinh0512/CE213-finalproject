//==============================================================
// LYRIC ROM MODULE - BƯỚC 3
//
// Thông số:
//   - Tổng số dòng  : 28 dòng (NUM_LINES)
//   - Độ dài mỗi dòng: 40 ký tự (LINE_WIDTH), padding bằng space
//   - Mỗi ký tự     : 8-bit ASCII (chỉ in hoa, A-Z, 0-9, space, dấu câu)
//
// Interface:
//   line_idx  : chỉ số dòng lyric muốn đọc (0 .. NUM_LINES-1)
//   char_idx  : chỉ số ký tự trong dòng    (0 .. LINE_WIDTH-1)
//   char_out  : mã ASCII của ký tự tại vị trí đó
//
// Cách dùng từ text_renderer:
//   char_out → font_rom addr[10:4]
//   (char_idx được text_renderer tính từ pixel_x / 8)
//==============================================================

module lyric_rom (
    input  wire        clk,
    input  wire [4:0]  line_idx,   // 0..27  (5 bit đủ cho 28 dòng)
    input  wire [5:0]  char_idx,   // 0..39  (6 bit đủ cho 40 ký tự)
    output reg  [7:0]  char_out    // ASCII code của ký tự
);

    //----------------------------------------------------------
    // THAM SỐ
    //----------------------------------------------------------
    localparam NUM_LINES  = 28;
    localparam LINE_WIDTH = 40;

    //----------------------------------------------------------
    // ROM: mảng 2D [dòng][cột]
    // Khai báo dạng packed để Quartus inference Block RAM
    //----------------------------------------------------------
    reg [7:0] rom [0 : NUM_LINES*LINE_WIDTH - 1];
    // Truy cập: rom[ line_idx * LINE_WIDTH + char_idx ]

    //----------------------------------------------------------
    // NỘI DUNG LYRIC (đã latin hóa, in hoa, padding space)
    // Bài: "Anh Do Mixi" (fan-made)
    //
    // Gốc                          → Latin hóa in hoa
    // "Nà ná na na"                → "NA NA NA NA"
    // "anh Phùng Thanh Độ"         → "ANH PHUNG THANH DO"
    // "anh Độ Mixi, Phùng Thanh Độ"→ "ANH DO MIXI, PHUNG THANH DO"
    // "anh Độ Mixi"                → "ANH DO MIXI"
    // "Cảm ơn anh, anh Độ Mixi"   → "CAM ON ANH, ANH DO MIXI"
    // "Phùng Thanh Độ, anh Độ Mixiii"→"PHUNG THANH DO, ANH DO MIXIII"
    // "Anh Độ Mixíiii..."          → "ANH DO MIXIIIIIIIIIIIIIIIIIIII"
    // "Anh Độ Mixi"                → "ANH DO MIXI"
    // "Anh Độ Mixi"                → "ANH DO MIXI"
    // "Anh Độ Mixi"                → "ANH DO MIXI"
    // "Anh tên là Anh Độ"          → "ANH TEN LA ANH DO"
    // "Anh Độ Mixi Na na Mami"     → "ANH DO MIXI NA NA MAMI"
    // "Cảm ơn anh"                 → "CAM ON ANH"
    // "Vì đã mang lại tiếng cười"  → "VI DA MANG LAI TIENG CUOI"
    // "Cho bọn em hàng ngày"       → "CHO BON EM HANG NGAY"
    // "Cảm ơn anh"                 → "CAM ON ANH"
    // "Vì những buổi stream"       → "VI NHUNG BUOI STREAM"
    // "Êm đềm em đi chơi"          → "EM DEM EM DI CHOI"
    // "Mời em đi quẩy khắp nơi"   → "MOI EM DI QUAY KHAP NOI"
    // "Nhưng mà em vẫn cứ thích"   → "NHUNG MA EM VAN CU THICH"
    // "Anh Độ Mixi"                → "ANH DO MIXI"
    // "Yeah! Yeah! Mixi!"          → "YEAH! YEAH! MIXI!"
    // "Anh Độ Mixi"                → "ANH DO MIXI"
    // "Anh tên là Thanh Độ"        → "ANH TEN LA THANH DO"
    // "Mình gọi là Anh Độ Mixi"   → "MINH GOI LA ANH DO MIXI"
    // "Anh tên là Thanh Độ"        → "ANH TEN LA THANH DO"
    // "Mình gọi là Anh Độ Mixi"   → "MINH GOI LA ANH DO MIXI"
    //----------------------------------------------------------

    // Task tiện ích: ghi 1 dòng vào ROM
    // Verilog không có string indexing trực tiếp nên dùng
    // assign từng byte thủ công theo từng dòng bên dưới.

    integer i;

    initial begin
        // Xóa toàn bộ ROM về space (0x20)
        for (i = 0; i < NUM_LINES * LINE_WIDTH; i = i + 1)
            rom[i] = 8'h20;

        //------------------------------------------------------
        // Macro viết tắt: base = line_idx * LINE_WIDTH
        // Mỗi dòng viết: rom[base + 0] = "X", rom[base+1]="Y"...
        //------------------------------------------------------

        // --- Dòng 0: "NA NA NA NA" ---
        rom[0*40+ 0]=8'h4E; rom[0*40+ 1]=8'h41; // N A
        rom[0*40+ 2]=8'h20;                       //  
        rom[0*40+ 3]=8'h4E; rom[0*40+ 4]=8'h41; // N A
        rom[0*40+ 5]=8'h20;                       //  
        rom[0*40+ 6]=8'h4E; rom[0*40+ 7]=8'h41; // N A
        rom[0*40+ 8]=8'h20;                       //  
        rom[0*40+ 9]=8'h4E; rom[0*40+10]=8'h41; // N A

        // --- Dòng 1: "ANH PHUNG THANH DO" ---
        rom[1*40+ 0]=8'h41; rom[1*40+ 1]=8'h4E; rom[1*40+ 2]=8'h48; // A N H
        rom[1*40+ 3]=8'h20;                                            //  
        rom[1*40+ 4]=8'h50; rom[1*40+ 5]=8'h48; rom[1*40+ 6]=8'h55; // P H U
        rom[1*40+ 7]=8'h4E; rom[1*40+ 8]=8'h47;                      // N G
        rom[1*40+ 9]=8'h20;                                            //  
        rom[1*40+10]=8'h54; rom[1*40+11]=8'h48; rom[1*40+12]=8'h41; // T H A
        rom[1*40+13]=8'h4E; rom[1*40+14]=8'h48;                      // N H
        rom[1*40+15]=8'h20;                                            //  
        rom[1*40+16]=8'h44; rom[1*40+17]=8'h4F;                      // D O

        // --- Dòng 2: "ANH DO MIXI, PHUNG THANH DO" ---
        rom[2*40+ 0]=8'h41; rom[2*40+ 1]=8'h4E; rom[2*40+ 2]=8'h48; // A N H
        rom[2*40+ 3]=8'h20;                                            //  
        rom[2*40+ 4]=8'h44; rom[2*40+ 5]=8'h4F;                      // D O
        rom[2*40+ 6]=8'h20;                                            //  
        rom[2*40+ 7]=8'h4D; rom[2*40+ 8]=8'h49; rom[2*40+ 9]=8'h58; // M I X
        rom[2*40+10]=8'h49;                                            // I
        rom[2*40+11]=8'h2C;                                            // ,
        rom[2*40+12]=8'h20;                                            //  
        rom[2*40+13]=8'h50; rom[2*40+14]=8'h48; rom[2*40+15]=8'h55; // P H U
        rom[2*40+16]=8'h4E; rom[2*40+17]=8'h47;                      // N G
        rom[2*40+18]=8'h20;                                            //  
        rom[2*40+19]=8'h54; rom[2*40+20]=8'h48; rom[2*40+21]=8'h41; // T H A
        rom[2*40+22]=8'h4E; rom[2*40+23]=8'h48;                      // N H
        rom[2*40+24]=8'h20;                                            //  
        rom[2*40+25]=8'h44; rom[2*40+26]=8'h4F;                      // D O

        // --- Dòng 3: "ANH DO MIXI" ---
        rom[3*40+ 0]=8'h41; rom[3*40+ 1]=8'h4E; rom[3*40+ 2]=8'h48; // A N H
        rom[3*40+ 3]=8'h20;                                            //  
        rom[3*40+ 4]=8'h44; rom[3*40+ 5]=8'h4F;                      // D O
        rom[3*40+ 6]=8'h20;                                            //  
        rom[3*40+ 7]=8'h4D; rom[3*40+ 8]=8'h49; rom[3*40+ 9]=8'h58; // M I X
        rom[3*40+10]=8'h49;                                            // I

        // --- Dòng 4: "CAM ON ANH, ANH DO MIXI" ---
        rom[4*40+ 0]=8'h43; rom[4*40+ 1]=8'h41; rom[4*40+ 2]=8'h4D; // C A M
        rom[4*40+ 3]=8'h20;                                            //  
        rom[4*40+ 4]=8'h4F; rom[4*40+ 5]=8'h4E;                      // O N
        rom[4*40+ 6]=8'h20;                                            //  
        rom[4*40+ 7]=8'h41; rom[4*40+ 8]=8'h4E; rom[4*40+ 9]=8'h48; // A N H
        rom[4*40+10]=8'h2C;                                            // ,
        rom[4*40+11]=8'h20;                                            //  
        rom[4*40+12]=8'h41; rom[4*40+13]=8'h4E; rom[4*40+14]=8'h48; // A N H
        rom[4*40+15]=8'h20;                                            //  
        rom[4*40+16]=8'h44; rom[4*40+17]=8'h4F;                      // D O
        rom[4*40+18]=8'h20;                                            //  
        rom[4*40+19]=8'h4D; rom[4*40+20]=8'h49; rom[4*40+21]=8'h58; // M I X
        rom[4*40+22]=8'h49;                                            // I

        // --- Dòng 5: "PHUNG THANH DO, ANH DO MIXIII" ---
        rom[5*40+ 0]=8'h50; rom[5*40+ 1]=8'h48; rom[5*40+ 2]=8'h55; // P H U
        rom[5*40+ 3]=8'h4E; rom[5*40+ 4]=8'h47;                      // N G
        rom[5*40+ 5]=8'h20;                                            //  
        rom[5*40+ 6]=8'h54; rom[5*40+ 7]=8'h48; rom[5*40+ 8]=8'h41; // T H A
        rom[5*40+ 9]=8'h4E; rom[5*40+10]=8'h48;                      // N H
        rom[5*40+11]=8'h20;                                            //  
        rom[5*40+12]=8'h44; rom[5*40+13]=8'h4F;                      // D O
        rom[5*40+14]=8'h2C;                                            // ,
        rom[5*40+15]=8'h20;                                            //  
        rom[5*40+16]=8'h41; rom[5*40+17]=8'h4E; rom[5*40+18]=8'h48; // A N H
        rom[5*40+19]=8'h20;                                            //  
        rom[5*40+20]=8'h44; rom[5*40+21]=8'h4F;                      // D O
        rom[5*40+22]=8'h20;                                            //  
        rom[5*40+23]=8'h4D; rom[5*40+24]=8'h49; rom[5*40+25]=8'h58; // M I X
        rom[5*40+26]=8'h49; rom[5*40+27]=8'h49; rom[5*40+28]=8'h49; // I I I

        // --- Dòng 6: "ANH DO MIXIIIIIIIIIIIIIIIIIIII" (30 ký tự) ---
        rom[6*40+ 0]=8'h41; rom[6*40+ 1]=8'h4E; rom[6*40+ 2]=8'h48; // A N H
        rom[6*40+ 3]=8'h20;                                            //  
        rom[6*40+ 4]=8'h44; rom[6*40+ 5]=8'h4F;                      // D O
        rom[6*40+ 6]=8'h20;                                            //  
        rom[6*40+ 7]=8'h4D; rom[6*40+ 8]=8'h49; rom[6*40+ 9]=8'h58; // M I X
        // 21 chữ I còn lại (vị trí 10..30)
        rom[6*40+10]=8'h49; rom[6*40+11]=8'h49; rom[6*40+12]=8'h49;
        rom[6*40+13]=8'h49; rom[6*40+14]=8'h49; rom[6*40+15]=8'h49;
        rom[6*40+16]=8'h49; rom[6*40+17]=8'h49; rom[6*40+18]=8'h49;
        rom[6*40+19]=8'h49; rom[6*40+20]=8'h49; rom[6*40+21]=8'h49;
        rom[6*40+22]=8'h49; rom[6*40+23]=8'h49; rom[6*40+24]=8'h49;
        rom[6*40+25]=8'h49; rom[6*40+26]=8'h49; rom[6*40+27]=8'h49;
        rom[6*40+28]=8'h49; rom[6*40+29]=8'h49; rom[6*40+30]=8'h49;

        // --- Dòng 7: "ANH DO MIXI" ---
        rom[7*40+ 0]=8'h41; rom[7*40+ 1]=8'h4E; rom[7*40+ 2]=8'h48;
        rom[7*40+ 3]=8'h20;
        rom[7*40+ 4]=8'h44; rom[7*40+ 5]=8'h4F;
        rom[7*40+ 6]=8'h20;
        rom[7*40+ 7]=8'h4D; rom[7*40+ 8]=8'h49; rom[7*40+ 9]=8'h58;
        rom[7*40+10]=8'h49;

        // --- Dòng 8: "ANH DO MIXI" ---
        rom[8*40+ 0]=8'h41; rom[8*40+ 1]=8'h4E; rom[8*40+ 2]=8'h48;
        rom[8*40+ 3]=8'h20;
        rom[8*40+ 4]=8'h44; rom[8*40+ 5]=8'h4F;
        rom[8*40+ 6]=8'h20;
        rom[8*40+ 7]=8'h4D; rom[8*40+ 8]=8'h49; rom[8*40+ 9]=8'h58;
        rom[8*40+10]=8'h49;

        // --- Dòng 9: "ANH DO MIXI" ---
        rom[9*40+ 0]=8'h41; rom[9*40+ 1]=8'h4E; rom[9*40+ 2]=8'h48;
        rom[9*40+ 3]=8'h20;
        rom[9*40+ 4]=8'h44; rom[9*40+ 5]=8'h4F;
        rom[9*40+ 6]=8'h20;
        rom[9*40+ 7]=8'h4D; rom[9*40+ 8]=8'h49; rom[9*40+ 9]=8'h58;
        rom[9*40+10]=8'h49;

        // --- Dòng 10: "ANH TEN LA ANH DO" ---
        rom[10*40+ 0]=8'h41; rom[10*40+ 1]=8'h4E; rom[10*40+ 2]=8'h48;
        rom[10*40+ 3]=8'h20;
        rom[10*40+ 4]=8'h54; rom[10*40+ 5]=8'h45; rom[10*40+ 6]=8'h4E; // T E N
        rom[10*40+ 7]=8'h20;
        rom[10*40+ 8]=8'h4C; rom[10*40+ 9]=8'h41;                       // L A
        rom[10*40+10]=8'h20;
        rom[10*40+11]=8'h41; rom[10*40+12]=8'h4E; rom[10*40+13]=8'h48;  // A N H
        rom[10*40+14]=8'h20;
        rom[10*40+15]=8'h44; rom[10*40+16]=8'h4F;                        // D O

        // --- Dòng 11: "ANH DO MIXI NA NA MAMI" ---
        rom[11*40+ 0]=8'h41; rom[11*40+ 1]=8'h4E; rom[11*40+ 2]=8'h48;
        rom[11*40+ 3]=8'h20;
        rom[11*40+ 4]=8'h44; rom[11*40+ 5]=8'h4F;
        rom[11*40+ 6]=8'h20;
        rom[11*40+ 7]=8'h4D; rom[11*40+ 8]=8'h49; rom[11*40+ 9]=8'h58;
        rom[11*40+10]=8'h49;
        rom[11*40+11]=8'h20;
        rom[11*40+12]=8'h4E; rom[11*40+13]=8'h41;                        // N A
        rom[11*40+14]=8'h20;
        rom[11*40+15]=8'h4E; rom[11*40+16]=8'h41;                        // N A
        rom[11*40+17]=8'h20;
        rom[11*40+18]=8'h4D; rom[11*40+19]=8'h41; rom[11*40+20]=8'h4D;  // M A M
        rom[11*40+21]=8'h49;                                               // I

        // --- Dòng 12: "CAM ON ANH" ---
        rom[12*40+ 0]=8'h43; rom[12*40+ 1]=8'h41; rom[12*40+ 2]=8'h4D;
        rom[12*40+ 3]=8'h20;
        rom[12*40+ 4]=8'h4F; rom[12*40+ 5]=8'h4E;
        rom[12*40+ 6]=8'h20;
        rom[12*40+ 7]=8'h41; rom[12*40+ 8]=8'h4E; rom[12*40+ 9]=8'h48;

        // --- Dòng 13: "VI DA MANG LAI TIENG CUOI" ---
        rom[13*40+ 0]=8'h56; rom[13*40+ 1]=8'h49;                        // V I
        rom[13*40+ 2]=8'h20;
        rom[13*40+ 3]=8'h44; rom[13*40+ 4]=8'h41;                        // D A
        rom[13*40+ 5]=8'h20;
        rom[13*40+ 6]=8'h4D; rom[13*40+ 7]=8'h41; rom[13*40+ 8]=8'h4E;  // M A N
        rom[13*40+ 9]=8'h47;                                               // G
        rom[13*40+10]=8'h20;
        rom[13*40+11]=8'h4C; rom[13*40+12]=8'h41; rom[13*40+13]=8'h49;  // L A I
        rom[13*40+14]=8'h20;
        rom[13*40+15]=8'h54; rom[13*40+16]=8'h49; rom[13*40+17]=8'h45;  // T I E
        rom[13*40+18]=8'h4E; rom[13*40+19]=8'h47;                        // N G
        rom[13*40+20]=8'h20;
        rom[13*40+21]=8'h43; rom[13*40+22]=8'h55; rom[13*40+23]=8'h4F;  // C U O
        rom[13*40+24]=8'h49;                                               // I

        // --- Dòng 14: "CHO BON EM HANG NGAY" ---
        rom[14*40+ 0]=8'h43; rom[14*40+ 1]=8'h48; rom[14*40+ 2]=8'h4F;  // C H O
        rom[14*40+ 3]=8'h20;
        rom[14*40+ 4]=8'h42; rom[14*40+ 5]=8'h4F; rom[14*40+ 6]=8'h4E;  // B O N
        rom[14*40+ 7]=8'h20;
        rom[14*40+ 8]=8'h45; rom[14*40+ 9]=8'h4D;                        // E M
        rom[14*40+10]=8'h20;
        rom[14*40+11]=8'h48; rom[14*40+12]=8'h41; rom[14*40+13]=8'h4E;  // H A N
        rom[14*40+14]=8'h47;                                               // G
        rom[14*40+15]=8'h20;
        rom[14*40+16]=8'h4E; rom[14*40+17]=8'h47; rom[14*40+18]=8'h41;  // N G A
        rom[14*40+19]=8'h59;                                               // Y

        // --- Dòng 15: "CAM ON ANH" ---
        rom[15*40+ 0]=8'h43; rom[15*40+ 1]=8'h41; rom[15*40+ 2]=8'h4D;
        rom[15*40+ 3]=8'h20;
        rom[15*40+ 4]=8'h4F; rom[15*40+ 5]=8'h4E;
        rom[15*40+ 6]=8'h20;
        rom[15*40+ 7]=8'h41; rom[15*40+ 8]=8'h4E; rom[15*40+ 9]=8'h48;

        // --- Dòng 16: "VI NHUNG BUOI STREAM" ---
        rom[16*40+ 0]=8'h56; rom[16*40+ 1]=8'h49;                        // V I
        rom[16*40+ 2]=8'h20;
        rom[16*40+ 3]=8'h4E; rom[16*40+ 4]=8'h48; rom[16*40+ 5]=8'h55;  // N H U
        rom[16*40+ 6]=8'h4E; rom[16*40+ 7]=8'h47;                        // N G
        rom[16*40+ 8]=8'h20;
        rom[16*40+ 9]=8'h42; rom[16*40+10]=8'h55; rom[16*40+11]=8'h4F;  // B U O
        rom[16*40+12]=8'h49;                                               // I
        rom[16*40+13]=8'h20;
        rom[16*40+14]=8'h53; rom[16*40+15]=8'h54; rom[16*40+16]=8'h52;  // S T R
        rom[16*40+17]=8'h45; rom[16*40+18]=8'h41; rom[16*40+19]=8'h4D;  // E A M

        // --- Dòng 17: "EM DEM EM DI CHOI" ---
        rom[17*40+ 0]=8'h45; rom[17*40+ 1]=8'h4D;                        // E M
        rom[17*40+ 2]=8'h20;
        rom[17*40+ 3]=8'h44; rom[17*40+ 4]=8'h45; rom[17*40+ 5]=8'h4D;  // D E M
        rom[17*40+ 6]=8'h20;
        rom[17*40+ 7]=8'h45; rom[17*40+ 8]=8'h4D;                        // E M
        rom[17*40+ 9]=8'h20;
        rom[17*40+10]=8'h44; rom[17*40+11]=8'h49;                        // D I
        rom[17*40+12]=8'h20;
        rom[17*40+13]=8'h43; rom[17*40+14]=8'h48; rom[17*40+15]=8'h4F;  // C H O
        rom[17*40+16]=8'h49;                                               // I

        // --- Dòng 18: "MOI EM DI QUAY KHAP NOI" ---
        rom[18*40+ 0]=8'h4D; rom[18*40+ 1]=8'h4F; rom[18*40+ 2]=8'h49;  // M O I
        rom[18*40+ 3]=8'h20;
        rom[18*40+ 4]=8'h45; rom[18*40+ 5]=8'h4D;                        // E M
        rom[18*40+ 6]=8'h20;
        rom[18*40+ 7]=8'h44; rom[18*40+ 8]=8'h49;                        // D I
        rom[18*40+ 9]=8'h20;
        rom[18*40+10]=8'h51; rom[18*40+11]=8'h55; rom[18*40+12]=8'h41;  // Q U A
        rom[18*40+13]=8'h59;                                               // Y
        rom[18*40+14]=8'h20;
        rom[18*40+15]=8'h4B; rom[18*40+16]=8'h48; rom[18*40+17]=8'h41;  // K H A
        rom[18*40+18]=8'h50;                                               // P
        rom[18*40+19]=8'h20;
        rom[18*40+20]=8'h4E; rom[18*40+21]=8'h4F; rom[18*40+22]=8'h49;  // N O I

        // --- Dòng 19: "NHUNG MA EM VAN CU THICH" ---
        rom[19*40+ 0]=8'h4E; rom[19*40+ 1]=8'h48; rom[19*40+ 2]=8'h55;  // N H U
        rom[19*40+ 3]=8'h4E; rom[19*40+ 4]=8'h47;                        // N G
        rom[19*40+ 5]=8'h20;
        rom[19*40+ 6]=8'h4D; rom[19*40+ 7]=8'h41;                        // M A
        rom[19*40+ 8]=8'h20;
        rom[19*40+ 9]=8'h45; rom[19*40+10]=8'h4D;                        // E M
        rom[19*40+11]=8'h20;
        rom[19*40+12]=8'h56; rom[19*40+13]=8'h41; rom[19*40+14]=8'h4E;  // V A N
        rom[19*40+15]=8'h20;
        rom[19*40+16]=8'h43; rom[19*40+17]=8'h55;                        // C U
        rom[19*40+18]=8'h20;
        rom[19*40+19]=8'h54; rom[19*40+20]=8'h48; rom[19*40+21]=8'h49;  // T H I
        rom[19*40+22]=8'h43; rom[19*40+23]=8'h48;                        // C H

        // --- Dòng 20: "ANH DO MIXI" ---
        rom[20*40+ 0]=8'h41; rom[20*40+ 1]=8'h4E; rom[20*40+ 2]=8'h48;
        rom[20*40+ 3]=8'h20;
        rom[20*40+ 4]=8'h44; rom[20*40+ 5]=8'h4F;
        rom[20*40+ 6]=8'h20;
        rom[20*40+ 7]=8'h4D; rom[20*40+ 8]=8'h49; rom[20*40+ 9]=8'h58;
        rom[20*40+10]=8'h49;

        // --- Dòng 21: "YEAH! YEAH! MIXI!" ---
        rom[21*40+ 0]=8'h59; rom[21*40+ 1]=8'h45; rom[21*40+ 2]=8'h41;  // Y E A
        rom[21*40+ 3]=8'h48; rom[21*40+ 4]=8'h21;                        // H !
        rom[21*40+ 5]=8'h20;
        rom[21*40+ 6]=8'h59; rom[21*40+ 7]=8'h45; rom[21*40+ 8]=8'h41;  // Y E A
        rom[21*40+ 9]=8'h48; rom[21*40+10]=8'h21;                        // H !
        rom[21*40+11]=8'h20;
        rom[21*40+12]=8'h4D; rom[21*40+13]=8'h49; rom[21*40+14]=8'h58;  // M I X
        rom[21*40+15]=8'h49; rom[21*40+16]=8'h21;                        // I !

        // --- Dòng 22: "ANH DO MIXI" ---
        rom[22*40+ 0]=8'h41; rom[22*40+ 1]=8'h4E; rom[22*40+ 2]=8'h48;
        rom[22*40+ 3]=8'h20;
        rom[22*40+ 4]=8'h44; rom[22*40+ 5]=8'h4F;
        rom[22*40+ 6]=8'h20;
        rom[22*40+ 7]=8'h4D; rom[22*40+ 8]=8'h49; rom[22*40+ 9]=8'h58;
        rom[22*40+10]=8'h49;

        // --- Dòng 23: "ANH TEN LA THANH DO" ---
        rom[23*40+ 0]=8'h41; rom[23*40+ 1]=8'h4E; rom[23*40+ 2]=8'h48;
        rom[23*40+ 3]=8'h20;
        rom[23*40+ 4]=8'h54; rom[23*40+ 5]=8'h45; rom[23*40+ 6]=8'h4E;  // T E N
        rom[23*40+ 7]=8'h20;
        rom[23*40+ 8]=8'h4C; rom[23*40+ 9]=8'h41;                        // L A
        rom[23*40+10]=8'h20;
        rom[23*40+11]=8'h54; rom[23*40+12]=8'h48; rom[23*40+13]=8'h41;  // T H A
        rom[23*40+14]=8'h4E; rom[23*40+15]=8'h48;                        // N H
        rom[23*40+16]=8'h20;
        rom[23*40+17]=8'h44; rom[23*40+18]=8'h4F;                        // D O

        // --- Dòng 24: "MINH GOI LA ANH DO MIXI" ---
        rom[24*40+ 0]=8'h4D; rom[24*40+ 1]=8'h49; rom[24*40+ 2]=8'h4E;  // M I N
        rom[24*40+ 3]=8'h48;                                               // H
        rom[24*40+ 4]=8'h20;
        rom[24*40+ 5]=8'h47; rom[24*40+ 6]=8'h4F; rom[24*40+ 7]=8'h49;  // G O I
        rom[24*40+ 8]=8'h20;
        rom[24*40+ 9]=8'h4C; rom[24*40+10]=8'h41;                        // L A
        rom[24*40+11]=8'h20;
        rom[24*40+12]=8'h41; rom[24*40+13]=8'h4E; rom[24*40+14]=8'h48;  // A N H
        rom[24*40+15]=8'h20;
        rom[24*40+16]=8'h44; rom[24*40+17]=8'h4F;                        // D O
        rom[24*40+18]=8'h20;
        rom[24*40+19]=8'h4D; rom[24*40+20]=8'h49; rom[24*40+21]=8'h58;  // M I X
        rom[24*40+22]=8'h49;                                               // I

        // --- Dòng 25: "ANH TEN LA THANH DO" (lặp lại) ---
        rom[25*40+ 0]=8'h41; rom[25*40+ 1]=8'h4E; rom[25*40+ 2]=8'h48;
        rom[25*40+ 3]=8'h20;
        rom[25*40+ 4]=8'h54; rom[25*40+ 5]=8'h45; rom[25*40+ 6]=8'h4E;
        rom[25*40+ 7]=8'h20;
        rom[25*40+ 8]=8'h4C; rom[25*40+ 9]=8'h41;
        rom[25*40+10]=8'h20;
        rom[25*40+11]=8'h54; rom[25*40+12]=8'h48; rom[25*40+13]=8'h41;
        rom[25*40+14]=8'h4E; rom[25*40+15]=8'h48;
        rom[25*40+16]=8'h20;
        rom[25*40+17]=8'h44; rom[25*40+18]=8'h4F;

        // --- Dòng 26: "MINH GOI LA ANH DO MIXI" (lặp lại) ---
        rom[26*40+ 0]=8'h4D; rom[26*40+ 1]=8'h49; rom[26*40+ 2]=8'h4E;
        rom[26*40+ 3]=8'h48;
        rom[26*40+ 4]=8'h20;
        rom[26*40+ 5]=8'h47; rom[26*40+ 6]=8'h4F; rom[26*40+ 7]=8'h49;
        rom[26*40+ 8]=8'h20;
        rom[26*40+ 9]=8'h4C; rom[26*40+10]=8'h41;
        rom[26*40+11]=8'h20;
        rom[26*40+12]=8'h41; rom[26*40+13]=8'h4E; rom[26*40+14]=8'h48;
        rom[26*40+15]=8'h20;
        rom[26*40+16]=8'h44; rom[26*40+17]=8'h4F;
        rom[26*40+18]=8'h20;
        rom[26*40+19]=8'h4D; rom[26*40+20]=8'h49; rom[26*40+21]=8'h58;
        rom[26*40+22]=8'h49;

        // --- Dòng 27: dòng trống (kết thúc bài) ---
        // Đã được fill space từ vòng for ở trên, không cần ghi thêm

    end // initial

    //----------------------------------------------------------
    // ĐỌC ROM ĐỒNG BỘ
    // 1 chu kỳ latency — text_renderer cần compensate
    //----------------------------------------------------------
    always @(posedge clk) begin
        char_out <= rom[ line_idx * LINE_WIDTH + char_idx ];
    end

endmodule