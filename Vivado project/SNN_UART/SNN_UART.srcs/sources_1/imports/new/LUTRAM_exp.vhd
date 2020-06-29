LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exponentiation unit: computes the positive and negative weight variations depending on the last spikes given by the local and previous layer neurons, and 
-- outputs them if the correspondent spike has been produced in either of those
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity LUTRAM_exp is
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        spike :             in std_logic;                                   -- Local spike
        spike_prev :        in std_logic;                                   -- Spike of the correspondant neuron in the previous layer
        tau_spikes_local :  in std_logic_vector(T_BACK_bits-1 downto 0);    -- Simulation steps since the last spike of the local neuron
        tau_spikes_prev :   in std_logic_vector(T_BACK_bits-1 downto 0);    -- Simulation steps since the last spike of thecorrespondant neuron in the previous layer
        pos_der :           out signed(WEIGHT_QUANT-1 downto 0);            -- Value of the positive derivative for STDP
        neg_der :           out signed(WEIGHT_QUANT-1 downto 0)             -- Value of the negative derivative for STDP
    );
end LUTRAM_exp;

architecture behaviour of LUTRAM_exp is

    signal pos_exp, neg_exp : signed(WEIGHT_QUANT-1 downto 0);
    signal pos_der_tmp, neg_der_tmp : signed(WEIGHT_QUANT-1 downto 0);

begin

    process(reset, clk)
        begin
            if reset = '0' then 
                pos_der <= (others => '0');
                neg_der <= (others => '0');
            elsif (clk'event and clk = '1') then
                pos_der <= pos_der_tmp;
                neg_der <= neg_der_tmp;
            end if;
    end process;

    -- Checks that a spike has fired in order to output the weight variation
    pos_der_tmp <= pos_exp when spike = '1' else (others => '0');
    neg_der_tmp <= neg_exp when spike_prev = '1' else (others => '0');
    
    -- Computes the exponentials via a Look-Up Table
    pos_exp <= LUTRAM_pos(to_integer(unsigned(tau_spikes_prev))) when (to_integer(unsigned(tau_spikes_prev)) <= T_BACK)
                else (others => '0');
    neg_exp <= LUTRAM_neg(to_integer(unsigned(tau_spikes_local))) when (to_integer(unsigned(tau_spikes_local)) <= T_BACK)
                else (others => '0');
               
end behaviour;