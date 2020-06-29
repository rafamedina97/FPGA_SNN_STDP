LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.rl_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity that corresponds to a input neuron
------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
entity input_neuron is
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        -- Control inputs
        cnt_en :            in std_logic;                                   -- Enables counting
        spike_reg_en :      in std_logic;                                   -- Enables the register of the produced spike
        period_store_en :   in std_logic;                                   -- Enables the storing of the correspondant period
        cnt_srst :          in std_logic;                                   -- Resets the count
        valid_spike :       in std_logic;                                   -- Control signal for registering the spike
        tau_cnt_srst :      in std_logic;                                   -- Synchronous reset of the last spikes register
        -- General in/out
        period :            in unsigned(MAX_PER_bits-1 downto 0);           -- Period computed
        spike_out :         out std_logic;                                  -- Spike output
        tau_spikes_out :    out std_logic_vector(T_BACK_bits-1 downto 0)    -- Simulation steps since the last spike (if > T_BACK outputs 0)
    );
end input_neuron;

architecture behaviour of input_neuron is

    component input_neuron_core is
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
    end component;
    
    component tau_counter is
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            srst :              in std_logic;
            spike :             in std_logic;                                   -- Spike of the local neuron
            valid_spike :       in std_logic;                                   -- Control signal for registering the spike
            tau_spikes_out :    out std_logic_vector(T_BACK_bits-1 downto 0)    -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;

    signal spike_intern : std_logic;

begin

    U_CORE : input_neuron_core
        port map(
            reset =>            reset,
            clk =>              clk,
            -- Control inputs
            cnt_en =>           cnt_en,
            spike_reg_en =>     spike_reg_en,
            period_store_en =>  period_store_en,
            cnt_srst =>         cnt_srst,
            -- General in/out
            period =>           period,
            spike_out =>        spike_intern
        );
        
    U_TAU_CNT: tau_counter
        port map(
            reset =>            reset,
            clk =>              clk,
            srst =>             tau_cnt_srst,
            spike =>            spike_intern,
            valid_spike =>      valid_spike,
            tau_spikes_out =>   tau_spikes_out
        );
        
    spike_out <= spike_intern;

end behaviour;
