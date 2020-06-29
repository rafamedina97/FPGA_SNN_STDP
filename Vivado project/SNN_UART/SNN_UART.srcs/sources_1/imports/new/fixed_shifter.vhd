LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

entity fixed_shifter is
    generic(
       S_AMT: natural;  -- Number of digits to shift
       S_MODE: natural  -- Shift mode
    );
    port(
       s_in: in std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0); 
       shft: in std_logic;
       s_out: out std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0)
    );
end fixed_shifter;

architecture para_arch of fixed_shifter is

    constant L_SHIFT: natural := 0;
    constant R_SHIFT: natural := 1;
    constant L_ROTAT: natural := 2;
    constant R_ROTAT: natural := 3;

    signal sh_tmp, zero: std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);

begin

    zero <= (others=>'0');
    -- shift left
    l_sh_gen:
    if S_MODE=L_SHIFT generate
        sh_tmp <= s_in(WEIGHT_QUANT+FRAC_QUANT-S_AMT-1 downto 0) &
                    zero(WEIGHT_QUANT+FRAC_QUANT-1 downto WEIGHT_QUANT+FRAC_QUANT-S_AMT);
    end generate;
    -- rotate left
    l_rt_gen:
    if S_MODE=L_ROTAT generate
        sh_tmp <= s_in(WEIGHT_QUANT+FRAC_QUANT-S_AMT-1 downto 0) &
                    s_in(WEIGHT_QUANT+FRAC_QUANT-1 downto WEIGHT_QUANT+FRAC_QUANT-S_AMT);
    end generate;
    -- shift right
    r_sh_gen:
    if S_MODE=R_SHIFT generate
        sh_tmp <= zero(S_AMT-1 downto 0) &
                    s_in(WEIGHT_QUANT+FRAC_QUANT-1 downto S_AMT);
    end generate;
    -- rotate right
    r_rt_gen:
    if S_MODE=R_ROTAT generate
        sh_tmp <= s_in(S_AMT-1 downto 0) &
                    s_in(WEIGHT_QUANT+FRAC_QUANT-1 downto S_AMT);
    end generate;
    -- 2-to-1 multiplexer
    s_out <= sh_tmp when shft='1' else s_in;

 end para_arch;