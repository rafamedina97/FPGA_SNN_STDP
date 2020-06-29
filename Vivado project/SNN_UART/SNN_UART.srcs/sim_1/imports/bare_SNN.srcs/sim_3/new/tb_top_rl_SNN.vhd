LIBRARY STD;
USE STD.textio.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;
USE IEEE.std_logic_textio.all;

use work.rl_pkg.all;
use work.param_pkg.all;
use work.log2_pkg.all;
use work.int_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for the combination of general control, SNN and receptive layer
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_top_rl_SNN is
end tb_top_rl_SNN;

architecture behaviour of tb_top_rl_SNN is

    component top_rl_SNN is
        generic(
            LAYER_NUM :     integer;
            LAYER_SIZES :   int_vector(0 to LAYER_NUM-1)
        );
        port(
            reset :			  in std_logic;
            clk :		      in std_logic;
            frame :           in std_logic_vector(31 downto 0);                                   -- 4 input pixels for the receptive layer
            arrived :         in std_logic;                                                       -- Signal that the 4 pixels are valid
            info_out :        out std_logic_vector(15 downto 0);                                  -- RL info output for the current convoluting image
            nxt_img_ready :   out std_logic;                                                      -- Signals the uP that it's ready for the next image
            valid_winner :    out std_logic;                                                      -- Signals that the value of the winner neuron is valid
            winner_neuron :   out std_logic_vector(log2c(LAYER_SIZES(LAYER_NUM-1))-1 downto 0)    -- Tells which neuron won for the last image
        );
    end component;
    
    constant period : time := 3.333 ns;--3.077 ns;
    constant LAYER_NUM : integer := 3;
    constant LAYER_SIZES : int_vector(0 to LAYER_NUM-1) := (784, 20, 10);
    
    type sqr_image is array(integer range <>) of std_logic_vector(7 downto 0);
    signal image : sqr_image(0 to 32*32-1);
    
    signal clk, reset, arrived, nxt_img_ready, valid_winner : std_logic;
    signal frame : std_logic_vector(31 downto 0);
    signal info_out : std_logic_vector(15 downto 0);
    signal winner_neuron : std_logic_vector(log2c(LAYER_SIZES(LAYER_NUM-1))-1 downto 0);

begin

    UUT : top_rl_SNN
        generic map(
            LAYER_NUM =>    LAYER_NUM,
            LAYER_SIZES =>  LAYER_SIZES
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            frame =>            frame,
            arrived =>          arrived,
            info_out =>         info_out,
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
        file f : text;
        variable L : line;
        variable buf : std_logic_vector(7 downto 0);
    
    begin
    
        reset <= '0';   arrived <= '0';    frame <= (others => '0');
        image <= (others => (others => '0'));
        
        wait until clk'event and clk = '1';
        wait for 5*period;
        reset <= '1';
        wait for period;
        
        --file_open(f, "../../../../x_train.txt", read_mode);
        file_open(f, "C:/Users/rafam/VivadoProjects/bare_SNN/x_train.txt", read_mode);
        
        for n in 0 to 24 loop
            
            -- Initialization of random image
            image <= (others => (others => '0'));
            
            
--            for j in 2 to 32-3 loop
--                for i in 2 to 32-3 loop
--                    uniform(seed1,seed2,rand);
--                    image(j*32+i) <= std_logic_vector(to_unsigned(integer(rand*255),8));
--                end loop;
--            end loop;
            
            -- Image info
--            arrived <= '1';
--            uniform(seed1,seed2,rand);
--            frame <= std_logic_vector(to_unsigned(integer(rand*255),32));
            
            arrived <= '1';
            frame <= (others => '0');
            readline(f,L);
            hread(L, buf);
            frame(7 downto 0) <= buf;
            
            for j in 0 to 31 loop   -- Read image from file
                for i in 0 to 31 loop
                    readline(f,L);
                    hread(L, buf);
                    image(j*32+i) <= buf;
                end loop;
            end loop;
            
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
        
        wait for 350000*period;
    
        file_close(f);
    
        assert false report "FIN" severity failure;
        
    end process;

end behaviour;