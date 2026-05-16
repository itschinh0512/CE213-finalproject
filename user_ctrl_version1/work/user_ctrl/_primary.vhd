library verilog;
use verilog.vl_types.all;
entity user_ctrl is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        sw              : in     vl_logic_vector(6 downto 0);
        key_n           : in     vl_logic_vector(2 downto 0);
        gain            : out    vl_logic_vector(6 downto 0);
        mute            : out    vl_logic;
        volume_level    : out    vl_logic_vector(3 downto 0);
        sw_override     : out    vl_logic
    );
end user_ctrl;
