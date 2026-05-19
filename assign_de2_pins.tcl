# DE2 pin assignments for the lyrics_vga_top revision.
# The DE2 VGA DAC has 10 color bits per channel. This design drives 4 bits
# per channel, so they are mapped to the DAC's upper bits [9:6].
#
# Run from this project directory with:
#   quartus_sh -t assign_de2_pins.tcl
#
# Or in Quartus GUI:
#   Tools -> Tcl Scripts... -> assign_de2_pins.tcl -> Run

if {![is_project_open]} {
    project_open -revision vga_sync vga_sync
}

set_global_assignment -name TOP_LEVEL_ENTITY lyrics_vga_top

set_location_assignment PIN_N2  -to {CLOCK_50}
set_location_assignment PIN_G26 -to {KEY0}
set_location_assignment PIN_N23 -to {KEY1}
set_location_assignment PIN_P23 -to {KEY2}
set_location_assignment PIN_N25 -to {SW0}

set_location_assignment PIN_A7 -to {VGA_HS}
set_location_assignment PIN_D8 -to {VGA_VS}
set_location_assignment PIN_B8 -to {VGA_CLK}
set_location_assignment PIN_D6 -to {VGA_BLANK_N}
set_location_assignment PIN_B7 -to {VGA_SYNC_N}

set_location_assignment PIN_H11 -to {VGA_R[0]}
set_location_assignment PIN_H12 -to {VGA_R[1]}
set_location_assignment PIN_F11 -to {VGA_R[2]}
set_location_assignment PIN_E10 -to {VGA_R[3]}

set_location_assignment PIN_G11 -to {VGA_G[0]}
set_location_assignment PIN_D11 -to {VGA_G[1]}
set_location_assignment PIN_E12 -to {VGA_G[2]}
set_location_assignment PIN_D12 -to {VGA_G[3]}

set_location_assignment PIN_C11 -to {VGA_B[0]}
set_location_assignment PIN_B11 -to {VGA_B[1]}
set_location_assignment PIN_C12 -to {VGA_B[2]}
set_location_assignment PIN_B12 -to {VGA_B[3]}

foreach port {
    CLOCK_50
    KEY0 KEY1 KEY2 SW0
    VGA_HS VGA_VS VGA_CLK VGA_BLANK_N VGA_SYNC_N
    VGA_R[0] VGA_R[1] VGA_R[2] VGA_R[3]
    VGA_G[0] VGA_G[1] VGA_G[2] VGA_G[3]
    VGA_B[0] VGA_B[1] VGA_B[2] VGA_B[3]
} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $port
}

export_assignments
