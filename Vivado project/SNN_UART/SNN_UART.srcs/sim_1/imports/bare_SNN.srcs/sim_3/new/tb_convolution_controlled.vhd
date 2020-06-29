LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.rl_pkg.all;
use work.param_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for the control with the receptive layer
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_convolution_controlled is
end tb_convolution_controlled;

architecture behaviour of tb_convolution_controlled is

    component convolution_controlled is
        generic(
            Nbits :     integer;
            entero :    integer;
            fraccion :  integer;
            per_bits :  integer;
            INPUT_LAYER_SIZE :  integer;
            OUTPUT_LAYER_SIZE : integer
        );
        port(
            reset :			  in std_logic;
            clk :		      in std_logic;
            -- Receptive layer
            frame :           in std_logic_vector(31 downto 0);
            arrived :         in std_logic;
            info_out :        out std_logic_vector(15 downto 0);
            -- General control
            start_step :      out std_logic;
            step_num :        out unsigned(STEPS_bits-1 downto 0);
            step_finish :     in std_logic;
            spikes_out :      in std_logic_vector(OUTPUT_LAYER_SIZE-1 downto 0);
            period_store :    out std_logic;
            period_out :      out period_vector(INPUT_LAYER_SIZE-1 downto 0);
            nxt_img_ready :   out std_logic;
            valid_winner :    out std_logic;
            winner_neuron :   out std_logic_vector(log2c(OUTPUT_LAYER_SIZE)-1 downto 0)
        );
    end component;
    
    constant period : time := 10 ns;
    constant NBits : integer := 16;
    constant entero : integer := 4;
    constant fraccion : integer := 12;
    constant INPUT_LAYER_SIZE : integer := 784;
    constant OUTPUT_LAYER_SIZE : integer := 10;
    
    type sqr_image is array(integer range <>) of std_logic_vector(7 downto 0);
    signal image : sqr_image(0 to 32*32-1);
    type mult_results is array(integer range <>) of signed(32 downto 0);
    type conv_terms is array(integer range <>) of signed(NBits-1 downto 0);
    type sca_matrix is array(integer range <>) of signed(23 downto 0);
    
    constant sca0 : signed(23 downto 0) := "0000" & "0000" & "0001" & "0000" & "0000" & "0000";-- 1
    constant sca1 : signed(23 downto 0) := "0000" & "0000" & "0000" & "1010" & "0000" & "0000";-- 0.625
    constant sca2 : signed(23 downto 0) := "0000" & "0000" & "0000" & "0100" & "0000" & "0000";-- 0.25
    constant sca3 : signed(23 downto 0) := "1111" & "1111" & "1111" & "1100" & "0000" & "0000";-- -0.25
    constant sca4 : signed(23 downto 0) := "1111" & "1111" & "1111" & "1000" & "0000" & "0000";-- -.5
    
    constant sca : sca_matrix(0 to 24) := (sca4, sca3, sca2, sca3, sca4,
                                            sca3, sca2, sca1, sca2, sca3,
                                            sca2, sca1, sca0, sca1, sca2,
                                            sca3, sca2, sca1, sca2, sca3,
                                            sca4, sca3, sca2, sca3, sca4);
                                            
    constant one : std_logic_vector(entero+fraccion-1 downto 0) := (fraccion => '1', others => '0');
    
    signal clk, reset, arrived, start_step, step_finish, period_store, nxt_img_ready, valid_winner : std_logic;
    signal frame : std_logic_vector(31 downto 0);
    signal info_out : std_logic_vector(15 downto 0);
    signal step_num : unsigned(STEPS_bits-1 downto 0);
    signal spikes_out : std_logic_vector(OUTPUT_LAYER_SIZE-1 downto 0);
    signal period_out : period_vector(INPUT_LAYER_SIZE-1 downto 0);
    signal winner_neuron : std_logic_vector(log2c(OUTPUT_LAYER_SIZE)-1 downto 0);

begin

    UUT : convolution_controlled
        generic map(
            Nbits =>                NBits,
            entero =>               entero,
            fraccion =>             fraccion,
            per_bits =>             MAX_PER_bits,
            INPUT_LAYER_SIZE =>     INPUT_LAYER_SIZE,
            OUTPUT_LAYER_SIZE =>    OUTPUT_LAYER_SIZE
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            -- Receptive layer
            frame =>            frame,
            arrived =>          arrived,
            info_out =>         info_out,
            -- General control
            start_step =>       start_step,
            step_num =>         step_num,
            step_finish =>      step_finish,
            spikes_out =>       spikes_out,
            period_store =>     period_store,
            period_out =>       period_out,
            nxt_img_ready =>    nxt_img_ready,
            valid_winner =>     valid_winner,
            winner_neuron =>    winner_neuron
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
    
        reset <= '0';   arrived <= '0';    frame <= (others => '0');
        image <= (others => (others => '0'));
        
        wait for 5*period;
        reset <= '1';
        wait for period;
        
        for n in 0 to 99 loop
            
            -- Initialization of random image
            image <= (others => (others => '0'));
            for j in 2 to 32-3 loop
                for i in 2 to 32-3 loop
                    uniform(seed1,seed2,rand);
                    image(j*32+i) <= std_logic_vector(to_unsigned(integer(rand*255),8));
                end loop;
            end loop;
            
            -- Image info
            arrived <= '1';
            uniform(seed1,seed2,rand);
            frame <= std_logic_vector(to_unsigned(integer(rand*255),32));
            wait for period;
            
            -- Passing the image four pixels at a time
            for j in 2 to 32-3 loop
                for i in 0 to 6 loop
                    for k in 0 to 3 loop
                        frame((3-k)*8+7 downto (3-k)*8) <= image(j*32+(i*4)+2+k);
                    end loop;
                    wait for period;
                end loop;
            end loop;
            
            arrived <= '0';
            
            wait until nxt_img_ready'event and nxt_img_ready = '1';
            wait for 4*period;
        
        end loop;
        
        wait for 6000*period;
    
        assert false report "FIN" severity failure;
        
    end process;
    
    proc_SNN : process(clk, reset)  -- Simulates the behaviour of the SNN
    
        variable rand : real;
        variable seed1, seed2 : positive;
        variable cnt, i : integer;
    
    begin
        if reset = '0' then
            cnt := 0;
            step_finish <= '0';
            spikes_out <= (others => '0');
        elsif clk'event and clk = '1' then
            case cnt is
                when 0 =>
                    if start_step = '1' then
                        cnt := cnt + 1;
                    end if;
                    step_finish <= '0';
                    spikes_out <= (others => '0');
                when 1 to 9 =>
                    cnt := cnt + 1;
                    step_finish <= '0';
                    spikes_out <= (others => '0');
                when 10 =>
                    uniform(seed1,seed2,rand);
                    spikes_out <= (others => '0');
                    if rand > 0.9 and step_num < STEPS then -- 10% probability of outputing a random spikes
                        uniform(seed1,seed2,rand);
                        i := integer(rand*(OUTPUT_LAYER_SIZE-1));
                        spikes_out(i) <= '1';
                    end if;
                    cnt := 0;
                    step_finish <= '1';
                when others =>
                    cnt := 0;
                    step_finish <= '0';
                    spikes_out <= (others => '0');
            end case;
        end if;
    end process;
    
    check_proc : process(clk)
        variable pix_num, idx_x, idx_y : natural := 0;
        variable conv_pixels : sqr_image(0 to 24);
        variable mult : mult_results(0 to 24);
        variable terms : conv_terms(0 to 24);
        variable sum : signed(NBits-1 downto 0);
        variable interp_res : unsigned(NBits-1 downto 0);
        variable interp_mult : signed(2*Nbits-1 downto 0);
        variable freq_mult : unsigned(BITS_FREQ+NBits-1 downto 0);
        variable frequency : unsigned(BITS_FREQ-1 downto 0);
        variable period_res : period_vector(INPUT_LAYER_SIZE-1 downto 0) := (others => (others => '0'));
        
        variable sim_step : natural := 0;
        variable spikes_winner : std_logic_vector(OUTPUT_LAYER_SIZE-1 downto 0) := (others => '0');
        variable idx_winner : std_logic_vector(log2c(OUTPUT_LAYER_SIZE)-1 downto 0) := (others => '0');
    begin
        
        if (clk'event and clk = '0' and period_store = '1') then    -- Computes the period vector that the rl should give and compares
            for pix_num in 0 to INPUT_LAYER_SIZE-1 loop
                idx_y := pix_num / 28;  idx_x := pix_num rem 28;
            for j in 0 to 4 loop
                for i in 0 to 4 loop
                    conv_pixels(j*5+i) := image((idx_y+j)*32 + idx_x+i);
                end loop;
            end loop;
            sum := (others => '0');
            for i in 0 to 24 loop
                mult(i) := signed('0' & conv_pixels(i)) * sca(i);
                terms(i) := mult(i)(fraccion+INT_INTERP+8-1 downto 8);
                sum := sum + terms(i);
            end loop;
            if sum >= MAX_INTERP or sum(NBits-1) = '1' then
                interp_mult := (others => '0');
                interp_res := unsigned(one);
            else  
                interp_mult := sum * INTERP_1;
                interp_res := unsigned(std_logic_vector(interp_mult(2*fraccion+entero-1 downto fraccion))) + unsigned(std_logic_vector(INTERP_0));            
            end if;
            freq_mult := interp_res * AUX_STEPS_INV;
            frequency := freq_mult(BITS_FREQ+fraccion-1 downto fraccion);
            if to_integer(frequency) >= MIN_FREQ and to_integer(frequency) <= MAX_FREQ then
                period_res(pix_num) := to_unsigned(period_LUT(to_integer(frequency)),MAX_PER_bits);
            else
                period_res(pix_num) := to_unsigned(STEPS,MAX_PER_bits);
            end if;
            
            end loop;
            
            assert period_out = period_res report "Wrong period storing" severity error;
            
        end if;
        
        if (clk'event and clk='0') then -- Checks if the winner spikes are correctly stored
            if step_finish = '1' then
                if to_integer(unsigned(spikes_winner)) = 0 then
                    spikes_winner := spikes_out;
                end if;
                if sim_step < STEPS then
                    sim_step := sim_step + 1;
                else
                    sim_step := 0;
                end if;
            end if;
            if valid_winner = '1' then
                for i in OUTPUT_LAYER_SIZE-1 downto 0 loop
                    if spikes_winner(i) = '1' then
                        idx_winner := std_logic_vector(to_unsigned(i+1,idx_winner'length));
                    end if;
                end loop;
                assert idx_winner = winner_neuron report "Incorrect winner neuron" severity error;
                spikes_winner := (others => '0');
            end if;
        end if;
        
    end process;

end behaviour;