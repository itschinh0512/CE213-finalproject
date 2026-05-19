library verilog;
use verilog.vl_types.all;
entity vga_sync is
    port(
        clk             : in     vl_logic;
        reset_n         : in     vl_logic;
        VGA_HS          : out    vl_logic;
        VGA_VS          : out    vl_logic;
        video_on        : out    vl_logic;
        pixel_tick      : out    vl_logic;
        pixel_x         : out    vl_logic_vector(9 downto 0);
        pixel_y         : out    vl_logic_vector(9 downto 0)
    );
end vga_sync;
