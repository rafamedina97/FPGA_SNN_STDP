LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bit shift register that stores the previous layer neuron spike used for STDP for synchronization when it is used in LIF
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity prev_spikes_reg is
    port(
        reset :     in std_logic;
        clk :       in std_logic;
        d_in :      in std_logic;	-- Previous spike input
        d_out :     out std_logic	-- Previous spike output
    );
 end prev_spikes_reg;
 
 architecture behaviour of prev_spikes_reg is

    signal reg: std_logic_vector(3 downto 0);

 begin

    process(clk, reset)
    begin
        if reset = '0' then
            reg <= (others => '0');
        elsif clk'event and clk = '1' then
            reg <= d_in & reg(3 downto 1);
        end if;
	end process;
	
	d_out <= reg(0);

 end behaviour;