LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.rl_pkg.all;
use work.param_pkg.all;
use work.log2_pkg.all;
use work.int_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for the bare SNN
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_bare_SNN is
end tb_bare_SNN;

architecture behaviour of tb_bare_SNN is

    component bare_SNN is
        generic(
            LAYER_NUM :     integer;
            LAYER_SIZES :   int_vector(0 to LAYER_NUM-1)
        );
        port(
            reset :			in std_logic;
            clk :		    in std_logic;
            -- General control
            start_step :    in std_logic;                                           -- Signals the start of the computation of a simulation step
            step_num :      in unsigned(STEPS_bits-1 downto 0);                     -- Number of the simulation step to compute
            step_finish :   out std_logic;                                          -- Signals the end of the step computation
            -- Period control
            period_store :  in std_logic;                                           -- Enables the storing of the correspondant period
            period :        in period_vector(LAYER_SIZES(0)-1 downto 0);            -- Period computed
            -- Spikes output
            spikes_out :    out std_logic_vector(LAYER_SIZES(LAYER_NUM-1)-1 downto 0) -- Spike outputs of the output layer
        );
    end component;
    
    constant period : time := 10 ns;
    constant LAYER_NUM : integer := 4;
    constant LAYER_SIZES : int_vector(0 to LAYER_NUM-1) := (5, 10, 8, 4);
    
    signal reset, clk, start_step, step_finish, period_store : std_logic;
    signal step_num : unsigned(STEPS_bits-1 downto 0);
    signal period_in : period_vector(LAYER_SIZES(0)-1 downto 0);
    signal spikes_out : std_logic_vector(LAYER_SIZES(LAYER_NUM-1)-1 downto 0);

begin

    UUT : bare_SNN
        generic map(
            LAYER_NUM =>    LAYER_NUM,
            LAYER_SIZES =>  LAYER_SIZES
        )
        port map(
            reset =>        reset,
            clk =>          clk,
            -- General control
            start_step =>   start_step,
            step_num =>     step_num,
            step_finish =>  step_finish,
            -- Period control
            period_store => period_store,
            period =>       period_in,
            -- Spikes output
            spikes_out =>   spikes_out
        );

    proc_clk : process
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    process
    
        variable rand : real;
        variable seed1, seed2 : positive;
    
    begin
    
        reset <= '0';   start_step <= '0';  step_num <= (others => '0');
        period_store <= '0';    period_in <= (others => (others => '0'));
        
        wait for 5*period;
        reset <= '1';
        wait for period;
        
        --for n in 0 to 99 loop
            
            -- Initialization of random inputs
            period_in <= (others => (others => '0'));
            for i in LAYER_SIZES(0)-1 downto 0 loop
                uniform(seed1,seed2,rand);
                period_in(i) <= to_unsigned(integer(rand*MAX_PER),MAX_PER_bits);
            end loop;
            
            period_store <= '1';
            wait for period;
            period_store <= '0';
            wait for period;
            
            for i in 0 to STEPS loop
                step_num <= to_unsigned(i, STEPS_bits);
                start_step <= '1';
                wait for period;
                start_step <= '0';
                wait until step_finish'event and step_finish = '1';
                wait for period;
            end loop;
        
        --end loop;
    
        assert false report "FIN" severity failure;
        
    end process;

end behaviour;