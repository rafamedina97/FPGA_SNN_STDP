LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.param_pkg.all;
use work.rl_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for a hidden layer controlled by the network controls
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_hidden_layer is
end tb_hidden_layer;

architecture behaviour of tb_hidden_layer is

    component hidden_layer_controlled is
        generic(
            MAX_NEURONS :		  integer;
            PREV_LAYER_NEURONS :  integer;
            NEURONS :	          integer
        );
        port(
            reset :			    in std_logic;
            clk :		        in std_logic;
            -- General control
            start_step :        in std_logic;                       -- Signals the start of the computation of a simulation step
            step_num :          in unsigned(STEPS_bits-1 downto 0); -- Number of the simulation step to compute
            step_finish :       out std_logic;                      -- Signals the end of the computation
            -- General in/out ---------------------------------------------------------------------
            spike_pre_lay :         in std_logic_vector(PREV_LAYER_NEURONS-1 downto 0); -- Spike output from the previous layer
            tau_spikes_pre_lay :    in last_spikes_reg(PREV_LAYER_NEURONS-1 downto 0);  -- Simulation steps since the last spike (if > T_BACK outputs 0) from the previous layer
            spike_out :             out std_logic_vector(NEURONS-1 downto 0);           -- Spike output
            tau_spikes_out :        out last_spikes_reg(NEURONS-1 downto 0);            -- Simulation steps since the last spike (if > T_BACK outputs 0)
            -- Test outputs -----------------------------------------------------------------------
            ext_flag_li :           out std_logic;
            ext_input_li :          out std_logic;
            ext_spike_prev :        out std_logic_vector(NEURONS-1 downto 0);
            ext_tau_spikes_prev :   out last_spikes_reg(NEURONS-1 downto 0)
        );
    end component;
    
    constant period : time := 10 ns;
	constant MAX_NEURONS : integer := 8;
	constant PREV_LAYER_NEURONS : integer := 4;
    constant NEURONS : integer := 7;
    
    signal reset, clk : std_logic;
    signal start_step, step_finish, ext_flag_li, ext_input_li : std_logic;
    signal step_num : unsigned(STEPS_bits-1 downto 0);
    signal spike_pre_lay : std_logic_vector(PREV_LAYER_NEURONS-1 downto 0);
    signal tau_spikes_pre_lay : last_spikes_reg(PREV_LAYER_NEURONS-1 downto 0);
    signal spike_out, ext_spike_prev : std_logic_vector(NEURONS-1 downto 0);
    signal tau_spikes_out, ext_tau_spikes_prev : last_spikes_reg(NEURONS-1 downto 0);
    signal li_in_aux, li_flag_aux : std_logic;
    signal i_ext : integer;

begin

    UUT : hidden_layer_controlled
        generic map(
            MAX_NEURONS =>          MAX_NEURONS,
            PREV_LAYER_NEURONS =>   PREV_LAYER_NEURONS,
            NEURONS =>              NEURONS
        )
        port map(
            reset =>                reset,
            clk =>                  clk,
            -- General control
            start_step =>           start_step,
            step_num =>             step_num,
            step_finish =>          step_finish,
            -- General in/out ---------------------------------------------------------------------
            spike_pre_lay =>        spike_pre_lay,
            tau_spikes_pre_lay =>   tau_spikes_pre_lay,
            spike_out =>            spike_out,
            tau_spikes_out =>       tau_spikes_out,
            -- Test outputs -----------------------------------------------------------------------
            ext_flag_li =>          ext_flag_li,
            ext_input_li =>         ext_input_li,
            ext_spike_prev =>       ext_spike_prev,
            ext_tau_spikes_prev =>  ext_tau_spikes_prev
        );
        
    proc_clk : process
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    process
        variable rand : real;
        variable seed1, seed2 : positive;
        variable tau_sp_out, tau_sp_prev : last_spikes_reg(NEURONS-1 downto 0);
        variable sp_out, sp_prev : std_logic_vector(NEURONS-1 downto 0);
        variable li_in, li_flag, li_comp : std_logic;
    begin
        reset <= '0';   start_step <= '0';  step_num <= (others => '0');    li_comp := '0';
        
        wait for 5*period;
        reset <= '1';
        wait for period;
        
        for l in 0 to 99 loop
            
            step_num <= (others => '0');    li_comp := '0';
            spike_pre_lay <= (others => '0');   tau_spikes_pre_lay <= (others => (others => '0'));
            
            -- First step test
            start_step <= '1';
            wait for period;
            start_step <= '0';
            wait for 2*period;
            wait until clk'event and clk = '0';
            for i in 0 to MAX_NEURONS+n_ones_Kt+7 loop -- Step cycles
                i_ext <= i;
                -- Inter layer register shifting
                if i > 1 and i < MAX_NEURONS-2 then
                    for n in 0 to NEURONS-1 loop
                        sp_prev(n) := spike_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                        tau_sp_prev(n) := tau_spikes_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                    end loop;
                else sp_prev := ext_spike_prev; tau_sp_prev := ext_tau_spikes_prev;
                end if;
                -- Lateral inhibition register shifting
                if i > 0 and i < MAX_NEURONS+1 then
                    if i < NEURONS+1 then li_in := spike_out(i-1);
                    else li_in := '0';
                    end if;
                    li_comp := li_comp or li_in;
                else li_in := ext_input_li;
                end if;
                li_in_aux <= li_in;
                -- Lateral inhibition flag
                if i = MAX_NEURONS then li_flag := li_comp;
                else li_flag := ext_flag_li;
                end if;
                li_flag_aux <= li_flag;
                -- Last spikes register update
                    if i = MAX_NEURONS+3 then
                        for n in 0 to NEURONS-1 loop
                            if spike_out(n) = '1' then tau_sp_out(n) := std_logic_vector(to_unsigned(1,T_BACK_bits)); else
                                if unsigned(tau_sp_out(n)) < T_BACK and unsigned(tau_sp_out(n)) > 0 then
                                    tau_sp_out(n) := std_logic_vector(unsigned(tau_sp_out(n))+1);
                                else
                                    tau_sp_out(n) := (others => '0');
                                end if;
                            end if;
                        end loop;
                    else tau_sp_out := tau_spikes_out;
                    end if;
                -- Input data
                if i = MAX_NEURONS+n_ones_Kt+6 then
                    for n in 0 to PREV_LAYER_NEURONS-1 loop
                        uniform(seed1, seed2, rand);
                        if rand >= 0.5 then spike_pre_lay(n) <= '1'; else spike_pre_lay(n) <= '0'; end if;
                        uniform(seed1, seed2, rand);
                        tau_spikes_pre_lay(n) <= std_logic_vector(to_unsigned(integer(rand*(T_BACK-1)), T_BACK_bits));
                    end loop;
                end if;
                
                assert sp_prev = ext_spike_prev report "Spike inter layer register failed" severity error;
                assert tau_sp_prev = ext_tau_spikes_prev report "Tau inter layer register failed" severity error;
                assert li_in = ext_input_li report "LI register shift failed" severity error;
                assert li_flag = ext_flag_li report "LI flag generation failed" severity error;
                assert tau_sp_out = tau_spikes_out report "Last spikes register update failed" severity error;
                
                wait for period;
            end loop;
            
            wait until clk'event and clk = '0';
            wait for 2*period;
            
            -- Intermediate steps test
            for j in 1 to STEPS-1 loop
                step_num <= to_unsigned(j,STEPS_bits);  li_comp := '0';
                start_step <= '1';
                wait for period;
                start_step <= '0';
                wait for 2*period;
                wait until clk'event and clk = '0';
                for i in 0 to MAX_NEURONS+n_ones_Kt+7 loop  -- Step cycles
                    i_ext <= i;
                    -- Inter layer register shifting
                    if i > 1 and i < MAX_NEURONS-2 then
                        for n in 0 to NEURONS-1 loop
                            sp_prev(n) := spike_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                            tau_sp_prev(n) := tau_spikes_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                        end loop;
                    else sp_prev := ext_spike_prev; tau_sp_prev := ext_tau_spikes_prev;
                    end if;
                    -- Lateral inhibition register shifting
                    if i > 0 and i < MAX_NEURONS+1 then
                        if i < NEURONS+1 then li_in := spike_out(i-1);
                        else li_in := '0';
                        end if;
                        li_comp := li_comp or li_in;
                    else li_in := ext_input_li;
                    end if;
                    li_in_aux <= li_in;
                    -- Lateral inhibition flag
                    if i = MAX_NEURONS then li_flag := li_comp;
                    else li_flag := ext_flag_li;
                    end if;
                    li_flag_aux <= li_flag;
                    -- Last spikes register update
                    if i = MAX_NEURONS+3 then
                        for n in 0 to NEURONS-1 loop
                            if spike_out(n) = '1' then tau_sp_out(n) := std_logic_vector(to_unsigned(1,T_BACK_bits)); else
                                if unsigned(tau_sp_out(n)) < T_BACK and unsigned(tau_sp_out(n)) > 0 then
                                    tau_sp_out(n) := std_logic_vector(unsigned(tau_sp_out(n))+1);
                                else
                                    tau_sp_out(n) := (others => '0');
                                end if;
                            end if;
                        end loop;
                    else tau_sp_out := tau_spikes_out;
                    end if;
                    -- Input data
                    if i = MAX_NEURONS+n_ones_Kt+6 then
                        for n in 0 to PREV_LAYER_NEURONS-1 loop
                            uniform(seed1, seed2, rand);
                            if rand >= 0.5 then spike_pre_lay(n) <= '1'; else spike_pre_lay(n) <= '0'; end if;
                            uniform(seed1, seed2, rand);
                            tau_spikes_pre_lay(n) <= std_logic_vector(to_unsigned(integer(rand*(T_BACK-1)), T_BACK_bits));
                        end loop;
                    end if;
                    
                    assert sp_prev = ext_spike_prev report "Spike inter layer register failed" severity error;
                    assert tau_sp_prev = ext_tau_spikes_prev report "Tau inter layer register failed" severity error;
                    assert li_in = ext_input_li report "LI register shift failed" severity error;
                    assert li_flag = ext_flag_li report "LI flag generation failed" severity error;
                    assert tau_sp_out = tau_spikes_out report "Last spikes register update failed" severity error;
                    
                    wait for period;
                end loop;
                
                wait until clk'event and clk = '0';
                wait for 2*period;
                
            end loop;
            
            -- Final step test
            step_num <= to_unsigned(STEPS,STEPS_bits);  li_comp := '0';
            start_step <= '1';
            wait for period;
            start_step <= '0';
            wait for 2*period;
            wait until clk'event and clk = '0';
            for i in 0 to MAX_NEURONS+n_ones_Kt+7 loop  -- Step cycles
                i_ext <= i;
                -- Inter layer register shifting
                if i > 1 and i < MAX_NEURONS-2 then
                    for n in 0 to NEURONS-1 loop
                        sp_prev(n) := spike_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                        tau_sp_prev(n) := tau_spikes_pre_lay((n+i-2) mod PREV_LAYER_NEURONS);
                    end loop;
                else sp_prev := ext_spike_prev; tau_sp_prev := ext_tau_spikes_prev;
                end if;
                -- Lateral inhibition register shifting
                if i > 0 and i < MAX_NEURONS+1 then
                    if i < NEURONS+1 then li_in := spike_out(i-1);
                    else li_in := '0';
                    end if;
                    li_comp := li_comp or li_in;
                else li_in := ext_input_li;
                end if;
                li_in_aux <= li_in;
                -- Lateral inhibition flag
                if i = MAX_NEURONS then li_flag := li_comp;
                else li_flag := ext_flag_li;
                end if;
                li_flag_aux <= li_flag;
                -- Last spikes register update
                if i = MAX_NEURONS+3 then
                    for n in 0 to NEURONS-1 loop
                        if spike_out(n) = '1' then tau_sp_out(n) := std_logic_vector(to_unsigned(1,T_BACK_bits)); else
                            if unsigned(tau_sp_out(n)) < T_BACK and unsigned(tau_sp_out(n)) > 0 then
                                tau_sp_out(n) := std_logic_vector(unsigned(tau_sp_out(n))+1);
                            else
                                tau_sp_out(n) := (others => '0');
                            end if;
                        end if;
                    end loop;
                elsif i = MAX_NEURONS+n_ones_Kt+7 then tau_sp_out := (others => (others => '0'));
                else tau_sp_out := tau_spikes_out;
                end if;
                
                -- Input data
                if i = MAX_NEURONS+n_ones_Kt+6 then
                    spike_pre_lay <= (others => '0');   tau_spikes_pre_lay <= (others => (others => '0'));
                end if;
                
                assert sp_prev = ext_spike_prev report "Spike inter layer register failed" severity error;
                assert tau_sp_prev = ext_tau_spikes_prev report "Tau inter layer register failed" severity error;
                assert li_in = ext_input_li report "LI register shift failed" severity error;
                assert li_flag = ext_flag_li report "LI flag generation failed" severity error;
                assert tau_sp_out = tau_spikes_out report "Last spikes register update failed" severity error;
                
                wait for period;
            end loop;
            
            wait until clk'event and clk = '0';
            wait for 5*period;
            
        end loop;
        
        assert false report "FIN" severity failure;
        
    end process;

end behaviour;