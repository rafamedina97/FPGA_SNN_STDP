LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.param_pkg.all;
use work.rl_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for a input layer controlled by the network controls
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_input_layer is
end tb_input_layer;

architecture behaviour of tb_input_layer is

    component input_layer_controlled is
        generic(
            MAX_NEURONS :		integer;
            NEURONS :	        integer
        );
        port(
            reset :			    in std_logic;
            clk :		        in std_logic;
            -- General control
            start_step :        in std_logic;                       -- Signals the start of the computation of a simulation step
            step_num :          in unsigned(STEPS_bits-1 downto 0); -- Number of the simulation step to compute
            step_finish :       out std_logic;                      -- Signals the end of the computation
            -- Period control
            period_store :      in std_logic;                       -- Enables the storing of the correspondant period
            period :            in period_vector(NEURONS-1 downto 0);   -- Period computed
            -- Outputs
            spike_out :             out std_logic_vector(NEURONS-1 downto 0);   -- Spike output
            tau_spikes_out :        out last_spikes_reg(NEURONS-1 downto 0)     -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;
    
    constant period : time := 10 ns;
	constant MAX_NEURONS : integer := 8;
    constant NEURONS : integer := 4;
    
    signal reset, clk : std_logic;
    signal start_step, step_finish, period_store : std_logic;
    signal step_num : unsigned(STEPS_bits-1 downto 0);
    signal period_neuron : period_vector(NEURONS-1 downto 0);
    signal spike_out : std_logic_vector(NEURONS-1 downto 0);
    signal tau_spikes_out : last_spikes_reg(NEURONS-1 downto 0);

begin

    UUT : input_layer_controlled
        generic map(
            MAX_NEURONS =>  MAX_NEURONS,
            NEURONS =>      NEURONS
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            -- General control
            start_step =>       start_step,
            step_num =>         step_num,
            step_finish =>      step_finish,
            -- Period control
            period_store =>     period_store,
            period =>           period_neuron,
            -- Outputs
            spike_out =>        spike_out,
            tau_spikes_out =>   tau_spikes_out
        );
        
    proc_clk : process
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    process
        variable rand : real;
        variable seed1, seed2 : positive;
        variable tau_sp_out : last_spikes_reg(NEURONS-1 downto 0);
        variable sp_out : std_logic_vector(NEURONS-1 downto 0);
    begin
        reset <= '0';   start_step <= '0';  period_store <= '0';    step_num <= (others => '0');
        -- Generation of periods
        for i in 0 to NEURONS-1 loop
            uniform(seed1,seed2,rand);
            period_neuron(i) <= to_unsigned(integer(rand*(MAX_PER-1)),MAX_PER_bits);
        end loop;
        
        wait for 5*period;
        reset <= '1';
        wait for period;
        
        -- Period storing        
        period_store <= '1';
        wait for period;
        period_store <= '0';
        
        -- Steps 0 to STEPS-1
        for s in 0 to STEPS-1 loop
            step_num <= to_unsigned(s,STEPS_bits);
            start_step <= '1';
            wait for period;
            start_step <= '0';
            wait for 2*period;
            wait until clk'event and clk = '0';
            for i in 0 to MAX_NEURONS+n_ones_Kt+7 loop
                for n in 0 to NEURONS-1 loop
                    -- Spike update
                    if i = MAX_NEURONS+n_ones_Kt+7 then
                        if (s+2) rem to_integer(period_neuron(n)) = 0 then
                            sp_out(n) := '1';
                        else sp_out(n) := '0';
                        end if;
                    else sp_out(n) := spike_out(n);
                    end if;
                    -- Last spikes register update
                    if i = MAX_NEURONS+3 then
                        if spike_out(n) = '1' then tau_sp_out(n) := std_logic_vector(to_unsigned(1,T_BACK_bits)); else
                            if unsigned(tau_sp_out(n)) < T_BACK and unsigned(tau_sp_out(n)) > 0 then
                                tau_sp_out(n) := std_logic_vector(unsigned(tau_sp_out(n))+1);
                            else
                                tau_sp_out(n) := (others => '0');
                            end if;
                        end if;
                    else tau_sp_out(n) := tau_spikes_out(n);
                    end if;
                end loop;
                
                assert sp_out = spike_out report "Spike generation failed" severity error;
                assert tau_sp_out = tau_spikes_out report "Last spikes register failed" severity error;
                
                wait for period;
            end loop;           
        end loop;
        
        -- Last step
        step_num <= to_unsigned(STEPS,STEPS_bits);
        start_step <= '1';
        wait for period;
        start_step <= '0';
        wait for 2*period;
        wait until clk'event and clk = '0';
        for i in 0 to MAX_NEURONS+n_ones_Kt+7 loop
            for n in 0 to NEURONS-1 loop
                -- Spike update
                if i = MAX_NEURONS+n_ones_Kt+7 then
                    sp_out(n) := '0';
                else sp_out(n) := spike_out(n);
                end if;
                -- Last spikes register update
                if i = MAX_NEURONS+3 then
                    if spike_out(n) = '1' then tau_sp_out(n) := std_logic_vector(to_unsigned(1,T_BACK_bits)); else
                        if unsigned(tau_sp_out(n)) < T_BACK and unsigned(tau_sp_out(n)) > 0 then
                            tau_sp_out(n) := std_logic_vector(unsigned(tau_sp_out(n))+1);
                        else
                            tau_sp_out(n) := (others => '0');
                        end if;
                    end if;
                elsif i = MAX_NEURONS+n_ones_Kt+7 then tau_sp_out(n) := (others => '0');
                else tau_sp_out(n) := tau_spikes_out(n);
                end if;
            end loop;
            
            assert sp_out = spike_out report "Spike generation failed" severity error;
            assert tau_sp_out = tau_spikes_out report "Last spikes register failed" severity error;
            
            wait for period;
        end loop;           
        
        wait until clk'event and clk = '0';
        wait for 2*period;
        
        assert false report "FIN" severity failure;
        
    end process;

end behaviour;