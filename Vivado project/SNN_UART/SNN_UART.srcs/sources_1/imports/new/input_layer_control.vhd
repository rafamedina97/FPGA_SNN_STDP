LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity in charge of registering the input layer specific instructions from the general control and transmitting them to the input layer
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity input_layer_control is
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
end input_layer_control;

architecture behavioural of input_layer_control is

begin

    process(clk, reset)
    begin
        if reset = '0' then
            out_input_cnt_en <= '0';
            out_input_cnt_srst <= '0';
            out_valid_spike <= '0';
            out_tau_cnt_srst <= '0';
            out_spike_reg_en <= '0';
        elsif clk'event and clk = '1' then
            out_input_cnt_en <= in_input_cnt_en;
            out_input_cnt_srst <= in_input_cnt_srst;
            out_valid_spike <= in_valid_spike;
            out_tau_cnt_srst <= in_tau_cnt_srst;
            out_spike_reg_en <= in_spike_reg_en;
        end if;
    end process;

end behavioural;