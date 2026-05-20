# CE213 Karaoke Machine - Integrated Module Version 1

This folder is the merged DE2 karaoke system project.

## Controls

- `KEY[3]`: global reset, active low
- `KEY[2]`: mute toggle
- `KEY[1]`: next lyric line
- `KEY[0]`: previous lyric line
- `SW[3:0]`: volume `0..9`
- `SW[17]`: lyric mode, `0 = manual`, `1 = auto`

`SW[3:0]` values `10..15` are invalid and fall back to volume `5`.
`LEDR[4]` lights when the volume switch value is invalid.

## Quartus Notes

Open `karaoke_top.qpf` in Quartus II 13.0 SP1 and compile the `karaoke_top`
revision.

The checked-in `audio_pll.v` avoids the Quartus `altpll` megafunction so the
merged project can compile on Cyclone II without PLL fitting errors. It divides
`CLOCK_50` by 4 and drives `AUD_XCK` at 12.5 MHz.

WM8731 normally uses 12.288 MHz for the 48 kHz family. 12.5 MHz is close enough
to validate the merged datapath, but if exact audio sampling is required,
replace `audio_pll.v` with a MegaWizard-generated PLL:

- Input: `CLOCK_50` / 50.000 MHz
- Output `c0`: 12.288 MHz
- Ports: `areset`, `inclk0`, `c0`, `locked`
- Module name: `audio_pll`

The merged design holds the audio/I2C path in reset until `audio_pll.locked`
is high. VGA and lyric controls reset directly from `KEY[3]`.
