V4 fix direction:
- 0808 works only because WM8731 analog BYPASS is enabled; FPGA audio path is bypassed.
- 0812 enables DAC digital path, so ADC->FPGA->DAC needs a valid WM8731 master clock (AUD_XCK).
- Do NOT connect AUD_XCK directly to CLOCK_27 for digital path.

Quartus PLL required:
1) Tools -> MegaWizard Plug-In Manager -> ALTPLL
2) Input clock: CLOCK_27 = 27.000 MHz
3) Output c0: 18.432 MHz
4) Name the module: audio_pll
5) Ports should be: inclk0, c0
6) Add generated .qip/.v to project.

Use audio_loopback.v from this folder.
Use i2c_av_config.v from this folder.
Keep your other modules, or use the included fixed I2S TX/RX.

Important WM8731 registers in this version:
R4 = 0x12  => DACSEL=1, BYPASS=0, MUTEMIC=1. Audio must pass FPGA.
R7 = 0x42  => Codec master, I2S, 16-bit.
R8 = 0x00  => Normal mode for 18.432 MHz MCLK, 48 kHz family.
