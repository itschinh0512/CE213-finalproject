library verilog;
use verilog.vl_types.all;
entity sw_decoder is
    port(
        sw              : in     vl_logic_vector(6 downto 0);
        sw_level        : out    vl_logic_vector(3 downto 0);
        sw_gain         : out    vl_logic_vector(6 downto 0);
        sw_valid        : out    vl_logic
    );
end sw_decoder;
