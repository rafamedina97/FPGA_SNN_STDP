library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.log2_pkg.all;
use work.int_pkg.all;

entity top_SNN_uart is
    generic(
        LAYER_NUM :     integer := 3;
        LAYER_SIZES :   int_vector(0 to LAYER_NUM-1) := (784, 20, 10)
    );
    port(
        reset :			in std_logic;
        clk_in1_p :     in std_logic;
        clk_in1_n :     in std_logic;
        rx :            in std_logic;
        --tx :            out std_logic;
        start :         in std_logic;
        leds :          out std_logic_vector(3 downto 0)
    );
end top_SNN_uart;

architecture behavioural of top_SNN_uart is

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

    component driven_uart is
        port(
            clk :       in std_logic;
            reset :     in std_logic;
            rx :        in std_logic;
            tx :        out std_logic;
            start :     in std_logic;
            ready :     in std_logic;
            arrived :   out std_logic;
            frame_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component clk_wiz_0 is
        port(
            clk_out1 :  out std_logic;
            resetn :    in std_logic;
            clk_in1_p : in std_logic;
            clk_in1_n : in std_logic
        );
    end component;
    
    signal clk, ready, arrived, nreset, valid_winner : std_logic;
    signal frame_out : std_logic_vector(31 downto 0);
    signal winner_neuron : std_logic_vector(log2c(LAYER_SIZES(LAYER_NUM-1))-1 downto 0);
    
begin

    U_SNN : top_rl_SNN
        generic map(
            LAYER_NUM =>    LAYER_NUM,
            LAYER_SIZES =>  LAYER_SIZES
        )
        port map(
            reset =>            nreset,
            clk =>              clk,
            frame =>            frame_out,
            arrived =>          arrived,
            info_out =>         open,
            nxt_img_ready =>    ready,
            valid_winner =>     valid_winner,
            winner_neuron =>    winner_neuron
        );

    U_UART : driven_uart
        port map(
            clk =>          clk,
            reset =>        nreset,
            rx =>           rx,
            tx =>           open,
            start =>        start,
            ready =>        ready,
            arrived =>      arrived,
            frame_out =>    frame_out
        );

    U_CLK : clk_wiz_0
        port map(
            clk_out1 =>     clk,
            resetn =>       nreset,
            clk_in1_p =>    clk_in1_p,
            clk_in1_n =>    clk_in1_n
        );
        
    process(clk, nreset)
    begin
        if nreset = '0' then
            leds <= (others => '1');
        elsif clk'event and clk = '1' then
            if valid_winner = '1' then
                leds <= winner_neuron;
            end if;
        end if;
    end process;
    
    nreset <= not reset;

end behavioural;