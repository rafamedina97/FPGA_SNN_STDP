LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.rl_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity in charge of controlling all the neurons in the network within a time slice/step. The instructions given vary depending on the time step: if it is the 
-- first, intermediate or final step.
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity network_control is
    generic(
        MAX_NEURONS :   integer     -- Number of neurons of the larger layer
    );
    port(
        reset :             in std_logic;
        clk :               in std_logic;
        -- Communication interface
        start_step :        in std_logic;                       -- Signals the start of the computation of a simulation step
        step_num :          in unsigned(STEPS_bits-1 downto 0); -- Number of the simulation step to compute
        step_finish :       out std_logic;                      -- Signals the end of the computation
        -- Input neurons control
        input_cnt_en :      out std_logic;  -- Enables counting for the input layer neurons
        input_cnt_srst :    out std_logic;  -- Resets the input layer neurons counters      
        -- Shift registers control
        ilr_shift_en :      out std_logic;  -- Enables shifting in the inter-layer circular registers
        ilr_store_en :      out std_logic;  -- Enables the storing of data in the inter-layer circular registers
        lir_shift_en :      out std_logic;  -- Enables shifting in the lateral inhibition regsiters
        lir_store_en :      out std_logic;  -- Enables the storing of data in the lateral inhibition registers
        -- Layer control communication
        send_li_flag :      out std_logic;  -- Prompts the layer control to send the correspondant lateral inhibition flag
        send_V_srst :       out std_logic;  -- Prompts the layer control to reset the tension register
        -- STDP control
        we_ram :            out std_logic_vector(0 to 0);                                               -- Enables writing in the synaptic weights memories
        o_addr :            out std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);    -- Reading address of the synaptic weights memories
        w_addr :            out std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);    -- Writing address of the synaptic weights memories
        valid_spike :       out std_logic;                                                              -- Enables count for the last spikes counter
        tau_cnt_srst :      out std_logic;                                                              -- Resets the last spikes counters
        -- LIF control
        mux_sel :           out std_logic_vector(1 downto 0);               -- LIF multiplexor select signal
        shift :             out std_logic_vector(WEIGHT_bits-1 downto 0);   -- Shift in the barrel shifter in order to perform the multiplication
        V_reg_en :          out std_logic;                                  -- LIF tension register enable
        V_srst_en :         out std_logic;                                  -- LIF tension register synchronous reset enable
        acc_reg_en :        out std_logic;                                  -- LIF accumulator register enable
        acc_srst :          out std_logic;                                  -- LIF accumulator register synchronous reset
        spike_reg_en :      out std_logic                                   -- LIF spike register enable
    );
end network_control;

architecture behaviour of network_control is

    constant MN_bits : integer := log2c(MAX_NEURONS);

    signal count : integer;
    signal cnt_en : std_logic;
    signal first_step, last_step : std_logic;

begin

    -- The control initiates the count with the signal start_step, and when it finishes activates step_finish
    proc_count : process(clk, reset)
    begin
        if reset = '0' then
            count <= 0;     cnt_en <= '0';
            step_finish <= '0';
        elsif clk'event and clk = '1' then
            if start_step = '1' then
                cnt_en <= '1';
                count <= 0;
            end if;
            
            step_finish <= '0';
            if cnt_en = '1' and count = MAX_NEURONS+n_ones_Kt+9 then
                cnt_en <= '0';
                count <= 0;
                step_finish <= '1';
            elsif cnt_en = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    -- The different phases within a step are succedeed: first the STDP update, later pipelined with the first accumulation of LIF, and then the later steps of LIF:
    -- multiplication by Kt and adding V. At the end the spikes and resets are generated and applied
    proc_instr : process(clk, reset)
    begin
        if reset = '0' then
            input_cnt_en <= '0';    input_cnt_srst <= '0';
            we_ram <= "0";          o_addr <= (others => '0');      w_addr <= (others => '0');
            ilr_shift_en <= '0';    ilr_store_en <= '0';            
            valid_spike <= '0';      tau_cnt_srst <= '0';
            lir_shift_en <= '0';    lir_store_en <= '0';            send_li_flag <= '0';
            mux_sel <= "00";        shift <= (others => '0');       spike_reg_en <= '0';
            V_reg_en <= '0';        V_srst_en <= '0';               send_V_srst <= '0';
            acc_reg_en <= '0';      acc_srst <= '0';
        elsif clk'event and clk = '1' then
            input_cnt_en <= '0';    input_cnt_srst <= '0';
            we_ram <= "0";          o_addr <= (others => '0');      w_addr <= (others => '0');
            ilr_shift_en <= '0';    ilr_store_en <= '0';            
            valid_spike <= '0';      tau_cnt_srst <= '0';
            lir_shift_en <= '0';    lir_store_en <= '0';            send_li_flag <= '0';
            mux_sel <= "00";        shift <= (others => '0');       spike_reg_en <= '0';
            V_reg_en <= '0';        V_srst_en <= '0';               send_V_srst <= '0';
            acc_reg_en <= '0';      acc_srst <= '0';
            if cnt_en = '1' then
                if n_ones_Kt > 1 then
                    case count is   -- Warnings since the compiler doesn't know if MAX_NEURONS > 4 and n_ones_Kt > 1
                        when 0 =>                       -- Read spikes for lateral inhibition and synaptic weights for STDP
                            if last_step = '0' then
                                input_cnt_en <= '1';
                            end if;
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                        when 1 to 4 =>                  -- Read spikes for LI, sw and previous layer spikes and last spikes for STDP
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                        when 5 to MAX_NEURONS-1 =>      -- Read spikes for LI, sw and previous layer spikes and last spikes for STDP, begins sw writing and LIF accumulation
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS =>             -- Applies LI, reads previous layer data for STDP, writes new sw and LIF accumulation
                            send_li_flag <= '1';
                            V_srst_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+1 =>           -- Reads previous layer data for STDP, writes new sw and LIF accumulation
                            if first_step = '0'then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+2 =>           -- Updates last spikes register, writes new sw and LIF accumulation
                            valid_spike <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+3 =>           -- Writes new sw and LIF accumulation
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+4 =>           -- Writes new sw and LIF accumulation, begin shifting for Kt multiplication
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                            shift <= shifts_Kt(count - (MAX_NEURONS+4));
                        when MAX_NEURONS+5 to MAX_NEURONS+n_ones_Kt+3 =>    -- Kt multiplication and shifting
                            mux_sel <= "10";
                            acc_reg_en <= '1';
                            shift <= shifts_Kt(count - (MAX_NEURONS+4));
                        when MAX_NEURONS+n_ones_Kt+4 => -- Kt multiplication
                            mux_sel <= "10";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+5 => -- V addition and different modules reset
                            mux_sel <= "01";
                            acc_srst <= '1';
                            if last_step = '0' then
                                V_reg_en <= '1';
                            else 
                                send_V_srst <= '1';
                                V_srst_en <= '1';
                                input_cnt_srst <= '1';
                                tau_cnt_srst <= '1';
                            end if;
                        when MAX_NEURONS+n_ones_Kt+6 => -- Spike output
                            spike_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+7 => -- New data for inter layer and LI registers 
                            ilr_store_en <= '1';
                            lir_store_en <= '1';
                        when others =>
                    end case;
                elsif n_ones_Kt = 1 then
                    case count is   -- Warnings since the compiler doesn't know if MAX_NEURONS > 4 and n_ones_Kt > 1
                        when 0 =>
                            if last_step = '0' then
                                input_cnt_en <= '1';
                            end if;
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                        when 1 to 4 =>
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                        when 5 to MAX_NEURONS-1 =>
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS =>
                            send_li_flag <= '1';
                            V_srst_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+1 =>
                            if first_step = '0'then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+2 =>
                            valid_spike <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+3 =>
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+4 =>
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                            shift <= shifts_Kt(count - (MAX_NEURONS+4));
                        when MAX_NEURONS+n_ones_Kt+4 =>
                            mux_sel <= "10";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+5 =>
                            mux_sel <= "01";
                            acc_srst <= '1';
                            if last_step = '0' then
                                V_reg_en <= '1';
                            else 
                                send_V_srst <= '1';
                                V_srst_en <= '1';
                                input_cnt_srst <= '1';
                                tau_cnt_srst <= '1';
                            end if;
                        when MAX_NEURONS+n_ones_Kt+6 =>
                            spike_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+7 =>
                            ilr_store_en <= '1';
                            lir_store_en <= '1';
                        when others =>
                    end case;
                else
                    case count is   -- Warnings since the compiler doesn't know if MAX_NEURONS > 4 and n_ones_Kt > 1
                        when 0 =>
                            if last_step = '0' then
                                input_cnt_en <= '1';
                            end if;
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                        when 1 to 4 =>
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                        when 5 to MAX_NEURONS-1 =>
                            o_addr <= std_logic_vector(to_unsigned(count, MN_bits));
                            lir_shift_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS =>
                            send_li_flag <= '1';
                            V_srst_en <= '1';
                            ilr_shift_en <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+1 =>
                            if first_step = '0'then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+2 =>
                            valid_spike <= '1';
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+3 =>
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+4 =>
                            if first_step = '0' then
                                we_ram <= "1";
                            end if;
                            w_addr <= std_logic_vector(to_unsigned(count-5, MN_bits));
                            mux_sel <= "11";
                            acc_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+5 =>
                            mux_sel <= "01";
                            acc_srst <= '1';
                            if last_step = '0' then
                                V_reg_en <= '1';
                            else 
                                send_V_srst <= '1';
                                V_srst_en <= '1';
                                input_cnt_srst <= '1';
                                tau_cnt_srst <= '1';
                            end if;
                        when MAX_NEURONS+n_ones_Kt+6 =>
                            spike_reg_en <= '1';
                        when MAX_NEURONS+n_ones_Kt+7 =>
                            ilr_store_en <= '1';
                            lir_store_en <= '1';
                        when others =>
                    end case;
                end if;
            end if;
        end if;
    end process;

    first_step <= '1' when step_num = 0 else '0';
    last_step <= '1' when step_num = STEPS else '0';

end behaviour;