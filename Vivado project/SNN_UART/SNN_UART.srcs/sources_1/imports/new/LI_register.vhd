LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Shift register that stores the spikes given by a layer and transmits them to the layer control for lateral inhibition processing
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity LI_register is
    generic(
        NEURONS : integer
    );
    port(
        reset :     in std_logic;
        clk :       in std_logic;
        d_in :      in std_logic_vector(NEURONS-1 downto 0);    -- Lateral inhibition flag from each neuron
        valid_in :  in std_logic;                               -- Allows for storing the flags
        shift_en :  in std_logic;                               -- Enables the register shifting
        d_out :     out std_logic                               -- Serial output of the lateral inhibition flags
    );
 end LI_register;
 
 architecture behaviour of LI_register is

    signal reg: std_logic_vector(NEURONS-1 downto 0);

 begin

    process(clk, reset)
    begin
        if reset = '0' then
            reg <= (others => '0');
            d_out <= '0';
        elsif clk'event and clk = '1' then
            if valid_in = '1' then
                reg <= d_in;
            elsif shift_en = '1' then
                reg <= '0' & reg(NEURONS-1 downto 1);
                d_out <= reg(0);
            end if;
        end if;
    end process;

 end behaviour;