
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

PACKAGE UART_test IS

-------------------------------------------------------------------------------
-- Procedure for sending one byte over the RS232 serial input
-------------------------------------------------------------------------------
      procedure Transmit (
        signal   TX   : out std_logic;      -- serial line
        constant DATA : in  std_logic_vector(7 downto 0)); -- byte to be sent
      
END UART_test;

PACKAGE BODY UART_test IS

-----------------------------------------------------------------------------
-- Procedure for sending one byte over the RS232 serial input 
-----------------------------------------------------------------------------     
           procedure Transmit (
             signal   TX   : out std_logic;  -- serial output
             constant DATA : in  std_logic_vector(7 downto 0)) is
           begin
       
             TX <= '0';
             wait for 52083.33 ns;  -- about to send byte

             for i in 0 to 7 loop
               TX <= DATA(i);
               wait for 52083.33 ns;
             end loop;  -- i

             TX <= '1';
             wait for 52083.33 ns;

             TX <= '1';

           end Transmit;
           

END UART_test;

