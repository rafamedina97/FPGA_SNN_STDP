library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.log2_pkg.ALL;
use work.UART_test.all;
use ieee.math_real.all;

entity tb_driver is
end tb_driver;

architecture testbench of tb_driver is

    component UART_RX_driver is
        port(
           start : in STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           --
           rx_empty : in STD_LOGIC;
           rd_uart : out STD_LOGIC;
           d_uart_rx : in STD_LOGIC_VECTOR(7 downto 0);
           --
           ready : in STD_LOGIC;
           --
           arrived : out STD_LOGIC;
           frame : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    constant TCLK : time := 3.508772 ns;
    
    signal reset, clk, start, rx_empty, rd_uart, ready, arrived : std_logic;
    signal d_uart_rx : std_logic_vector(7 downto 0);
    signal frame : std_logic_vector(31 downto 0);
    signal cnt : natural := 0;

begin

    UUT : UART_RX_driver
        port map(
            reset => reset,
            clk => clk,
            start => start,
            rx_empty => rx_empty,
            rd_uart =>  rd_uart,
            d_uart_rx => d_uart_rx,
            ready => ready,
            arrived => arrived,
            frame => frame
        );
        
      -- Clock generator
    p_clk : PROCESS
    BEGIN
     clk <= '1', '0' after TCLK/2;
     wait for TCLK;
    END PROCESS;
    
    process 
        variable rand : real;
        variable seed1, seed2 : positive;
        variable data_rx : integer;
    begin
        reset <= '1';   rx_empty <= '1';  start <= '0'; ready <= '0';   d_uart_rx <= (others => '0');
        wait until clk'event and clk = '1';
        wait for 4*TCLK;
        reset <= '0';
        wait for 5*TCLK;
        
        start <= '1';   ready <= '1'; rx_empty <= '0';
        
        wait for TCLK;
        
        for i in 0 to 788 loop
            uniform(seed1, seed2, rand);
            data_rx := integer(rand*255);
            d_uart_rx <= std_logic_vector(to_unsigned(data_rx,8));
            wait for TCLK;
            if rd_uart = '0' then
                wait for TCLK;
            end if;
        end loop;
        
        rx_empty <= '1';
        
        wait for 100*TCLK;
        
        assert false report "Fin" severity failure;
        
    end process;
    
    process
    begin
        if arrived = '1' then
            cnt <= cnt + 1;
        end if;
        wait for TCLK;
    end process;
    
end testbench;
