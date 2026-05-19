transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/CE213.Q23/DoAnCE213.Q23/lyrics_vga_top {E:/CE213.Q23/DoAnCE213.Q23/lyrics_vga_top/vga_sync.v}

