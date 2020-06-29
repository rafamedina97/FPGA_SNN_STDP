LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

entity barrel_shifter is
    port(
        reset :   in std_logic;
        clk :   in std_logic;
        b_in :  in std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);
        shift : in std_logic_vector(WEIGHT_bits-1 downto 0);
        b_out : out std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0)
    );
end barrel_shifter;

architecture para_arch of barrel_shifter is

    constant STAGE: natural := WEIGHT_bits;
    constant S_MODE : natural := 0; -- Left shift

    type std_aoa_type is array(STAGE downto 0) of std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);
    signal p: std_aoa_type;

    component fixed_shifter is
        generic(
            S_AMT:     natural;
            S_MODE:    natural
        );
        port(
            s_in:  in std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);
            shft:  in std_logic;
            s_out: out std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0)
        );
    end component;

begin

    p(0) <= b_in;

    stage_gen:
    for s in 0 to (STAGE-1) generate
        shift_slice: fixed_shifter
            generic map(
                S_MODE =>   S_MODE,
                S_AMT =>    2**s
            )
            port map(
                s_in =>     p(s),
                s_out =>    p(s+1),
                shft =>     shift(s)
            );
    end generate;

    process(clk, reset)
    begin
        if reset = '0' then
            b_out <= (others => '0');
        elsif clk'event and clk = '1' then
            b_out <= p(STAGE);
        end if;
    end process;

end para_arch;