----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.12.2018 15:57:27
-- Design Name: 
-- Module Name: controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.log2_pkg.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_RX_driver is    
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
end UART_RX_driver;

architecture Behavioral of UART_RX_driver is

constant PIXELS : natural := 788;
constant FRAME_LEN : natural := 4;
constant FRAMES : natural := pixels/frame_len;

signal frame_next, frame_reg : unsigned (log2c(FRAMES)-1 downto 0) := (others => '0');
signal pix_next, pix_reg : unsigned (log2c(FRAME_LEN)-1 downto 0) := (others => '0');
signal frame_buf : std_logic_vector(31 downto 0);
signal frame_en, rd_uart_next : std_logic;
type fsmd_state_type is (idle, sampling, send_frame, waiting);
signal state_reg : fsmd_state_type := idle;
signal state_next : fsmd_state_type; 

begin

-- State and data registers
process (clk, reset)
begin
    if reset = '1' then
        frame_reg <= (others => '0');
        pix_reg <= (others => '0');
        state_reg <= idle;
        frame_buf <= (others => '0');
        rd_uart <= '0';
    elsif clk'event and clk = '1' then
        frame_reg <= frame_next;        
        pix_reg <= pix_next;
        state_reg <= state_next;
        if frame_en = '1' then
            frame_buf((3-to_integer(pix_reg))*8+7 downto (3-to_integer(pix_reg))*8) <= d_uart_rx;
        end if;
        rd_uart <= rd_uart_next;
    end if;
end process;

-- Next state logic & Data path 
process(start, ready, d_uart_rx, rx_empty, state_reg, frame_reg, pix_reg)
begin
    
    frame_next <= frame_reg;    
    pix_next <= pix_reg;    
    state_next <= state_reg;
    rd_uart_next <= '0';
    arrived <= '0';
    frame_en <= '0';
    
    case state_reg is    
        when idle =>            
            if (start = '0') then
                state_next <= idle;
            else
                state_next <= sampling;
            end if;            
        when sampling =>
            if (rx_empty = '0') then
                if pix_reg < FRAME_LEN-1 then
                    frame_en <= '1';
                    pix_next <= pix_reg + 1;
                    rd_uart_next <= '1';
                else
                    frame_en <= '1';
                    pix_next <= (others => '0');
                    rd_uart_next <= '1';
                    state_next <= send_frame;
                end if;
            end if;   
        when send_frame =>
            if frame_reg < FRAMES-1 then
                arrived <= '1';
                frame_next <= frame_reg + 1;
                state_next <= sampling;
            else
                arrived <= '1';
                frame_next <= (others => '0');
                state_next <= waiting;
            end if;
        when waiting =>
            if ready = '1' then
                state_next <= idle;
            end if;
    end case;
end process;

frame <= frame_buf;
     
end Behavioral;
