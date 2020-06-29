library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.log2_pkg.ALL;
use work.UART_test.all;
use ieee.math_real.all;

entity tb_top_uart is
end tb_top_uart;

architecture testbench of tb_top_uart is

    component top_SNN_uart is
        port(
            reset :			in std_logic;
            clk_in1_p :     in std_logic;
            clk_in1_n :     in std_logic;
            rx :            in std_logic;
            --tx :            out std_logic;
            start :         in std_logic;
            leds :          out std_logic_vector(3 downto 0)
        );
    end component;
    
    constant TCLK : time := 3.508772 ns;
    signal clk, clk_n, reset, rx, start : std_logic;
    signal leds : std_logic_vector(3 downto 0);

begin

    UUT : top_SNN_uart
        port map(
            reset => reset,
            clk_in1_p => clk,
            clk_in1_n => clk_n,
            rx => rx,
            start => start,
            leds => leds
        );
        
      -- Clock generator
    p_clk : PROCESS
    BEGIN
     clk <= '1', '0' after TCLK/2;
     wait for TCLK;
    END PROCESS;
    
    clk_n <= not clk;
    
    process 
        variable rand : real;
        variable seed1, seed2 : positive;
        variable data_rx : integer;
    begin
        reset <= '1';   rx <= '1';  start <= '0';
        wait until clk'event and clk = '1';
        wait for 4*TCLK;
        reset <= '0';
        wait for 500*TCLK;
        
        start <= '1';
        
        for i in 0 to 788 loop
            uniform(seed1, seed2, rand);
            data_rx :=  integer(rand*255.0);
            Transmit(rx, std_logic_vector(to_unsigned(data_rx,8)));
            wait for 50*TCLK;
        end loop;
        
        wait for 1000*TCLK;
        
        assert false report "Fin" severity failure;
        
    end process;
    
end testbench;
