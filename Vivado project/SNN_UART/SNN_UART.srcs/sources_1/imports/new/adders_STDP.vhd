LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity that perform all the additions needed for STDP and then keeps the result within the synpatic weight limits
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity adders_STDP is
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        exp_pos :           in signed(WEIGHT_QUANT-1 downto 0);             -- Value of the positive derivative for STDP
        exp_neg :           in signed(WEIGHT_QUANT-1 downto 0);             -- Value of the negative derivative for STDP
        syn_weight :        in std_logic_vector(WEIGHT_QUANT-1 downto 0);   -- Synaptic weight for the correspondant neuron in the previous layer
        next_syn_weight :   out std_logic_vector(WEIGHT_QUANT-1 downto 0)   -- Next synaptic weight for the correspondant neuron in the previous layer
    );
end adders_STDP;

architecture behaviour of adders_STDP is

    signal derivate, rec_weight : signed(WEIGHT_QUANT-1 downto 0);
    signal derivate_tmp, rec_weight_tmp : signed(WEIGHT_QUANT-1 downto 0);
    signal sum_result_tmp, sum_result, next_syn_weight_tmp : signed(WEIGHT_QUANT-1 downto 0);
    signal more_than_max, less_than_min : std_logic;

begin

    process(reset, clk)
    begin
        if reset = '0' then 
            rec_weight <= (others => '0');
            derivate <= (others => '0');
            sum_result <= (others => '0');
            next_syn_weight <= (others => '0');
        elsif (clk'event and clk = '1') then
            rec_weight <= rec_weight_tmp;
            derivate <= derivate_tmp;
            sum_result <= sum_result_tmp;
            next_syn_weight <= std_logic_vector(next_syn_weight_tmp);
        end if;
    end process;
    
    -- Pipelined additions for STDP
    derivate_tmp <= exp_pos + exp_neg;
    rec_weight_tmp <= signed(syn_weight) + SYN_REC;
    sum_result_tmp <= derivate + rec_weight;
    
    -- Checks if the result is within the limits and multiplexes accordingly
    more_than_max <= '1' when sum_result > W_max else '0';
    less_than_min <= '1' when sum_result < W_min else '0';
    
    next_syn_weight_tmp <= sum_result when more_than_max = '0' and less_than_min = '0'
                        else W_max when more_than_max = '1' and less_than_min = '0'
                        else W_min when more_than_max = '0' and less_than_min = '1'
                        else (others => '0');

end behaviour;