LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Circular register that stores the spikes and last spikes registers given by a layer and transmits them to the next layer in a one-to-one fashion
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity inter_layer_reg is
    generic(
        NEURONS : integer
    );
    port(
        reset :         in std_logic;                               
        clk :           in std_logic; 
        last_sp_in :    in last_spikes_reg(NEURONS-1 downto 0);     -- Input of the time of the last spike for each neuron
        spikes_in :     in std_logic_vector(NEURONS-1 downto 0);    -- Input of the spike for each neuron
        valid_in :      in std_logic;                               -- Allows for storing the data inputs
        shift_en :      in std_logic;                               -- Enables the shifting of registers
        last_sp_out :   out last_spikes_reg(NEURONS-1 downto 0);    -- Output for each register of the time of last spikes
        spikes_out :    out std_logic_vector(NEURONS-1 downto 0)    -- Output for each register of the spikes
    );
 end inter_layer_reg;
 
 architecture behaviour of inter_layer_reg is

    signal last_sp_reg : last_spikes_reg(NEURONS-1 downto 0);
    signal spikes_reg : std_logic_vector(NEURONS-1 downto 0);

 begin

    process(clk, reset)
    begin
        if reset = '0' then
            last_sp_reg <= (others => (others => '0'));
            spikes_reg <= (others => '0');
        elsif clk'event and clk = '1' then
            if valid_in = '1' then
                last_sp_reg <= last_sp_in;
                spikes_reg <= spikes_in;
            elsif shift_en = '1' then
                last_sp_reg <= last_sp_reg(0) & last_sp_reg(NEURONS-1 downto 1);
                spikes_reg <= spikes_reg(0) & spikes_reg(NEURONS-1 downto 1);
            end if;
        end if;
    end process;

    last_sp_out <= last_sp_reg;
    spikes_out <= spikes_reg;

 end behaviour;