LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.rl_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity grouping all the modules that compose the input layer
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity input_layer is
    generic(
        NEURONS :   integer
    );
    port(
        reset :                 in std_logic;
        clk :                   in std_logic;
        -- Control inputs
        in_input_cnt_en :       in std_logic;                               -- Enables counting for the input layer neurons
        in_input_cnt_srst :     in std_logic;                               -- Resets the input layer neurons counters
        in_valid_spike :        in std_logic;                               -- Enables count for the last spikes counter
        in_tau_cnt_srst :       in std_logic;                               -- Resets the last spikes counters
        in_spike_reg_en :       in std_logic;                               -- LIF spike register enable
        in_period_store :       in std_logic;                               -- Enables the storing of the correspondant period
        -- General in/out
        period :                in period_vector(NEURONS-1 downto 0);       -- Period computed
        spike_out :             out std_logic_vector(NEURONS-1 downto 0);   -- Spike output
        tau_spikes_out :        out last_spikes_reg(NEURONS-1 downto 0)     -- Simulation steps since the last spike (if > T_BACK outputs 0)
    );
end input_layer;

architecture behaviour of input_layer is

    component input_layer_control is
        port(
            reset :                 in std_logic;
            clk :                   in std_logic;
            -- Input neurons control
            in_input_cnt_en :       in std_logic;   -- Enables counting for the input layer neurons
            out_input_cnt_en :      out std_logic;
            in_input_cnt_srst :     in std_logic;   -- Resets the input layer neurons counters
            out_input_cnt_srst :    out std_logic;
            -- STDP control
            in_valid_spike :        in std_logic;   -- Enables count for the last spikes counter
            out_valid_spike :       out std_logic;
            in_tau_cnt_srst :       in std_logic;   -- Resets the last spikes counters
            out_tau_cnt_srst :      out std_logic;
            -- LIF control
            in_spike_reg_en :       in std_logic;   -- LIF spike register enable
            out_spike_reg_en :      out std_logic
        );
    end component;
    
    component input_neuron is
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
    end component;
    
    signal cnt_en, spike_reg_en, cnt_srst, valid_spike, tau_cnt_srst : std_logic;
    
begin

    U_IN_CONTROL : input_layer_control
        port map(
            reset =>                reset,
            clk =>                  clk,
            -- Input neurons control
            in_input_cnt_en =>      in_input_cnt_en,    
            out_input_cnt_en =>     cnt_en,
            in_input_cnt_srst =>    in_input_cnt_srst,
            out_input_cnt_srst =>   cnt_srst,
            -- STDP control
            in_valid_spike =>       in_valid_spike,
            out_valid_spike =>      valid_spike,
            in_tau_cnt_srst =>      in_tau_cnt_srst,
            out_tau_cnt_srst =>     tau_cnt_srst,
            -- LIF control
            in_spike_reg_en =>      in_spike_reg_en,
            out_spike_reg_en =>     spike_reg_en
        );
        
    NEURON_GEN :
    for n in 0 to NEURONS-1 generate
        U_NEURON : input_neuron
            port map(
                reset =>            reset,
                clk =>              clk,
                -- Control inputs
                cnt_en =>           cnt_en,
                spike_reg_en =>     spike_reg_en,
                period_store_en =>  in_period_store,
                cnt_srst =>         cnt_srst,
                valid_spike =>      valid_spike,
                tau_cnt_srst =>     tau_cnt_srst,
                -- General in/out
                period =>           period(n),
                spike_out =>        spike_out(n),
                tau_spikes_out =>   tau_spikes_out(n)
            );
    end generate;

end behaviour;