LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity in charge of performing the LIF computing. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity LIF is
    port(
        reset :         in std_logic;
        clk :           in std_logic;
        -- Control inputs
        mux_sel :       in std_logic_vector(1 downto 0);                -- Selection of the multiplexor           
        shift :         in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Bits the barrel shifter must shift
        V_reg_en :      in std_logic;                                   -- Tension register enable
        V_srst_en :     in std_logic;                                   -- Tension register synchronous reset enable
        acc_reg_en :    in std_logic;                                   -- Accumulator register enable
        acc_srst :      in std_logic;                                   -- Accumulator register synchronous reset
        spike_reg_en :  in std_logic;                                   -- Spike register enable
        -- General in/out
        spike_prev :    in std_logic;                                   -- Spike of the correspondant neuron in the previous layer
        syn_weight :    in signed(WEIGHT_QUANT-1 downto 0);             -- Synaptic weight for the correspondant neuron in the previous layer
        flag_li :       in std_logic;                                   -- Signal for lateral inhibition from control
        spike_out :     out std_logic                                   -- Neuron spike
    );
end LIF;

architecture behaviour of LIF is

    component barrel_shifter is
        port(
            reset : in std_logic;    
            clk :   in std_logic;
            b_in :  in std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);
            shift : in std_logic_vector(WEIGHT_bits-1 downto 0);
            b_out : out std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0)
        );
    end component;

    signal spike, spike_tmp, V_srst, V_min_flag : std_logic;
    signal V, V_neg_aux : signed(WEIGHT_QUANT-1 downto 0);
    signal acc, acc_tmp, mux_out, syn_weight_term : signed(WEIGHT_QUANT-1 downto 0);
    signal V_neg, V_shifted_term : std_logic_vector(WEIGHT_QUANT+FRAC_QUANT-1 downto 0);
    signal syn_weight_aux : signed(WEIGHT_QUANT-1 downto 0);

begin

    BS : barrel_shifter
        port map(
            reset =>    reset,
            clk =>      clk,
            b_in =>     V_neg,
            shift =>    shift,
            b_out =>    V_shifted_term
        );

    process(reset, clk)
    begin
        if reset = '0' then 
            V <= (others => '0');
            acc <= (others => '0');
            spike <= '0';
        elsif (clk'event and clk = '1') then
            if V_srst_en = '1' then
                if V_srst = '1' then
                    V <= (others => '0');
                end if;
            elsif V_reg_en = '1' then
                V <= acc_tmp;
            end if;

            if acc_srst = '1' then
                acc <= (others => '0');
            elsif acc_reg_en = '1' then
                acc <= acc_tmp;
            end if;

            if spike_reg_en = '1' then
                spike <= spike_tmp;
            end if;
        end if;
    end process;
    
    -- AND for the synaptic weight input
    AND_syn_weight:
    for b in WEIGHT_QUANT-1 downto 0 generate
        syn_weight_term(b) <= (syn_weight(b)) and spike_prev;
    end generate;
    
    V_neg_aux <= -V;
    
    -- Sign extension for multiplication by Kt
    Sign_extension_V_neg:
    for c in 1 to FRAC_QUANT generate
        V_neg(WEIGHT_QUANT+FRAC_QUANT-c) <= V_neg_aux(WEIGHT_QUANT-1);
    end generate;
    
    V_neg(WEIGHT_QUANT-1 downto 0) <= std_logic_vector(V_neg_aux);

    -- Selection of the mux between 0, accumulating the correct synaptic weights, multiplying by -Kt or adding V
    mux_out <= V when mux_sel = "01"
                else signed(V_shifted_term(WEIGHT_QUANT+FRAC_QUANT-1 downto FRAC_QUANT)) when mux_sel = "10"
                else syn_weight_term when mux_sel = "11"
                else (others => '0');
    
    -- Adder in the entity
    acc_tmp <= mux_out + acc;
    
    -- Comparators with V to generate the different signals and resets
    V_min_flag <= '1' when V < V_min else '0';
    spike_tmp <= '1' when V >= V_th else '0';
    V_srst <= V_min_flag or spike_tmp or flag_li;

    spike_out <= spike;

end behaviour;