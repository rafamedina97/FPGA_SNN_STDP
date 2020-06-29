LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity in charge of "translating" the network-wide control instructions to the specific layer, and register all instructions
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity layer_control is
    generic(
        MAX_NEURONS :     integer;    -- Number of neurons of the largest layer
        PREV_LAYER_NEURONS :   integer     -- Number of neurons in the layer
    );
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        -- Shift registers control
        in_ilr_shift_en :   in std_logic;   -- Enables shifting in the inter-layer circular registers
        out_ilr_shift_en :  out std_logic;
        in_ilr_store_en :   in std_logic;   -- Enables the storing of data in the inter-layer circular registers
        out_ilr_store_en :  out std_logic;
        in_lir_shift_en :   in std_logic;   -- Enables shifting in the lateral inhibition regsiters
        out_lir_shift_en :  out std_logic;
        in_lir_store_en :   in std_logic;   -- Enables the storing of data in the lateral inhibition registers
        out_lir_store_en :  out std_logic;
        -- Layer control communication
        in_send_li_flag :   in std_logic;   -- Prompts the layer control to send the correspondant lateral inhibition flag
        in_send_V_srst :    in std_logic;   -- Prompts the layer control to reset the tension register
        li_input :          in std_logic;   -- Lateral inhibition input from the shift register
        li_flag :           out std_logic;  -- Lateral inhibition output flag for the layer
        -- STDP control
        in_we_ram :         in std_logic_vector(0 to 0);                                            -- Enables writing in the synaptic weights memories
        out_we_ram :        out std_logic_vector(0 to 0);
        in_o_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Reading address of the synaptic weights memories
        out_o_addr :        out std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);
        in_w_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Writing address of the synaptic weights memories
        out_w_addr :        out std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);
        in_valid_spike :    in std_logic;                                                           -- Enables count for the last spikes counter
        out_valid_spike :   out std_logic;
        in_tau_cnt_srst :   in std_logic;                                                           -- Resets the last spikes counters
        out_tau_cnt_srst :  out std_logic;
        -- LIF control
        in_mux_sel :        in std_logic_vector(1 downto 0);                -- LIF multiplexor select signal
        out_mux_sel :       out std_logic_vector(1 downto 0);
        in_shift :          in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Shift in the barrel shifter in order to perform the multiplication
        out_shift :         out std_logic_vector(WEIGHT_bits-1 downto 0);
        in_V_reg_en :       in std_logic;                                   -- LIF tension register enable
        out_V_reg_en :      out std_logic;
        in_V_srst_en :      in std_logic;                                   -- LIF tension register synchronous reset enable
        out_V_srst_en :     out std_logic;
        in_acc_reg_en :     in std_logic;                                   -- LIF accumulator register enable
        out_acc_reg_en :    out std_logic;
        in_acc_srst :       in std_logic;                                   -- LIF accumulator register synchronous reset
        out_acc_srst :      out std_logic;
        in_spike_reg_en :   in std_logic;                                   -- LIF spike register enable
        out_spike_reg_en :  out std_logic
    );
end layer_control;

architecture behaviour of layer_control is

    signal li_reg, li_reg_tmp : std_logic;
    signal we_ram_tmp : std_logic_vector(0 downto 0);
    signal w_addr_tmp, o_addr_tmp : std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);
    signal acc_reg_en_tmp : std_logic;
    signal layer_write_en, layer_output_en : std_logic;

begin

    -- Registering every instruction to improve fanout
    process(clk, reset)
    begin
        if reset = '0' then
            out_ilr_shift_en <= '0';    out_ilr_store_en <= '0';
            out_lir_shift_en <= '0';    out_lir_store_en <= '0';
            li_reg <= '0';              li_flag <= '0';
            out_we_ram <= "0";          out_o_addr <= (others => '0');  out_w_addr <= (others => '0');
            out_valid_spike <= '0';     out_tau_cnt_srst <= '0';
            out_mux_sel <= "00";        out_shift <= (others => '0');
            out_V_reg_en <= '0';        out_V_srst_en <= '0';
            out_acc_reg_en <= '0';      out_acc_srst <= '0';
            out_spike_reg_en <= '0';
        elsif clk'event and clk = '1' then
            out_ilr_shift_en <= in_ilr_shift_en;
            out_ilr_store_en <= in_ilr_store_en;
            out_lir_shift_en <= in_lir_shift_en;
            out_lir_store_en <= in_lir_store_en;
            
            -- Layer lateral inhibition processing
            li_reg <= li_reg_tmp;
            li_flag <= '0';
            if in_send_V_srst = '1' then
                li_flag <= '1';
            elsif in_send_li_flag = '1' then
                li_flag <= li_reg_tmp;
            end if;

            out_we_ram <= we_ram_tmp;
            out_w_addr <= w_addr_tmp(log2c(PREV_LAYER_NEURONS)-1 downto 0);
            out_o_addr <= o_addr_tmp(log2c(PREV_LAYER_NEURONS)-1 downto 0);
            out_valid_spike <= in_valid_spike;
            out_tau_cnt_srst <= in_tau_cnt_srst;

            out_mux_sel <= in_mux_sel;
            out_shift <= in_shift;
            out_V_reg_en <= in_V_reg_en;
            out_V_srst_en <= in_V_srst_en;
            out_acc_reg_en <= acc_reg_en_tmp;
            out_acc_srst <= in_acc_srst;
            out_spike_reg_en <= in_spike_reg_en;
        end if;
    end process;
    
    -- OR for getting the LI flag
    li_reg_tmp <= '0' when in_valid_spike = '1' else li_input or li_reg;    -- Resets with a signal that activates at the "end" of each simulation step
    
    -- Limits synaptic weight reading and wirting to the number of neurons in the previous layer
    layer_write_en <= '1' when unsigned(in_w_addr) < PREV_LAYER_NEURONS else '0';
    layer_output_en <= '1' when unsigned(in_o_addr) < PREV_LAYER_NEURONS else '0';
    we_ram_tmp <= in_we_ram when layer_write_en = '1' else "0";
    w_addr_tmp <= in_w_addr when layer_write_en = '1' else (others => '0');
    o_addr_tmp <= in_o_addr when layer_output_en = '1' else (others => '0');

    -- Makes sure the accumulator in LIF is only enabled when the write address is within the correct range and the MUX select has a significant value
    acc_reg_en_tmp <= in_acc_reg_en when (layer_write_en = '1' or in_mux_sel = "10") else '0';

end behaviour;