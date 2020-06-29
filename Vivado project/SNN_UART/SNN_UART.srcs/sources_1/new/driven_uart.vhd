library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity driven_uart is
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
end driven_uart;

architecture behavioural of driven_uart is

    component uart is
        port(
          clk, reset: in std_logic;
          rd_uart, wr_uart: in std_logic;           -- Read from receiver, write to transmitter
          rx: in std_logic;                         -- UART RX
          w_data: in std_logic_vector(7 downto 0);  -- Data to be transmitted
          tx_full, rx_empty: out std_logic;         -- FIFO TX full, FIFO RX empty
          r_data: out std_logic_vector(7 downto 0); -- Data received
          tx: out std_logic                         -- UART TX
       );
    end component;
    
    component UART_RX_driver is    
        Port ( start : in STD_LOGIC;
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
    
    signal nreset, rd_uart, rx_empty : std_logic;
    signal r_data : std_logic_vector(7 downto 0);

begin

    U_UART : uart
        port map(
            clk => clk,
            reset => nreset,
            rd_uart => rd_uart,
            wr_uart => '0',
            rx => rx,
            tx => tx,
            w_data => (others => '0'),
            r_data => r_data,
            rx_empty => rx_empty,
            tx_full => open
        );

    U_DRIVER : UART_RX_driver
        port map(
            clk => clk,
            reset => nreset,
            start => start,
            rx_empty => rx_empty,
            rd_uart => rd_uart,
            d_uart_rx => r_data,
            ready => ready,
            arrived => arrived,
            frame => frame_out
        );

    nreset <= not reset;

end behavioural;