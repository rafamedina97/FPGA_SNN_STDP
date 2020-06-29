LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.rl_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity that corresponds to a input neuron core, i.e., the storing of the period and the counter
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity input_neuron_core is
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        -- Control inputs
        cnt_en :            in std_logic;                           -- Enables counting
        spike_reg_en :      in std_logic;                           -- Enables the register of the produced spike
        period_store_en :   in std_logic;                           -- Enables the storing of the correspondant period
        cnt_srst :          in std_logic;                           -- Resets the count
        -- General in/out
        period :            in unsigned(MAX_PER_bits-1 downto 0);   -- Period computed
        spike_out :         out std_logic                           -- Spike output
    );
end input_neuron_core;

architecture behaviour of input_neuron_core is
    
signal count, count_tmp, period_reg : unsigned(MAX_PER_bits-1 downto 0);
signal spike_tmp : std_logic;

begin

    process(clk, reset)
    begin
        if reset = '0' then
            count <= (others => '0');
            period_reg <= (others => '0');
            spike_out <= '0';
        elsif clk'event and clk = '1' then
            count <= count_tmp;
            if spike_reg_en = '1' then
                spike_out <= spike_tmp;
            end if;
            if period_store_en = '1' then
                period_reg <= period;
            end if;
        end if;
    end process;
    
    -- Count generation
    count_tmp <= (others => '0') when cnt_srst = '1'
            else count + 1 when cnt_en = '1' and spike_tmp = '0'
            else (others => '0') when cnt_en = '1'
            else count;
    
    -- Spike generation
    spike_tmp <= '1' when count = (period_reg-1) else '0';

end behaviour;