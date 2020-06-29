LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity that stores the last T_BACK spikes given by the neuron using a counter. It outputs the slices transcurred since the last spikes, or zero if the number 
-- is higher than T_BACK
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tau_counter is
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        srst :              in std_logic;
        spike :             in std_logic;                                   -- Spike of the local neuron
        valid_spike :       in std_logic;                                   -- Control signal for registering the spike
        tau_spikes_out :    out std_logic_vector(T_BACK_bits-1 downto 0)    -- Simulation steps since the last spike (if > T_BACK outputs 0)
    );
end tau_counter;

architecture behaviour of tau_counter is

    signal spikes_counter : unsigned(T_BACK_bits-1 downto 0);

begin

    process(reset, clk)
    begin
        if reset = '0' then
            spikes_counter <= (others => '0');
        elsif clk'event and clk = '1' then
            if srst = '1' then
                spikes_counter <= (others => '0');
            elsif valid_spike = '1' then
                -- Resets to 1 if a spike has fired, else adds one or resets to zero depending on the current count
                if spike = '1' then
                    spikes_counter <= to_unsigned(1, T_BACK_bits);
                elsif spikes_counter >= to_unsigned(T_BACK, T_BACK_bits) then
                    spikes_counter <= (others => '0');
                elsif spikes_counter /= to_unsigned(0, T_BACK_bits) then
                    spikes_counter <= spikes_counter + 1;
                end if;
            end if;
        end if;
    end process;

    tau_spikes_out <= std_logic_vector(spikes_counter);

end behaviour;