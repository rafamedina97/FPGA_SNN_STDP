----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.03.2019 10:57:31
-- Design Name: 
-- Module Name: Interpolation - Behavioral
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

use work.rl_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity interpolation is
    Generic ( entero: integer:= 4; fraccion: integer:= 12);
    Port ( pot : in STD_LOGIC_VECTOR (entero+fraccion-1 downto 0);
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid_in : in STD_LOGIC;
           valid_prop : out STD_LOGIC;
           inter_result : out STD_LOGIC_VECTOR (entero+fraccion-1 downto 0));
end Interpolation;

architecture Behavioral of interpolation is
-- range of value interpol destination / range of value to interpol
--constant delta2div1 : sfixed(entero downto -fraccion) := "0001010000000000";--5/4--"1111110010101011";--  -(5/24)
--"0001110011000100"; -- 5/2.781
--"0001000011111100"; -- 5/4.781 = 1.xx
--constant delta2 : sfixed(entero downto -fraccion) := "0000000000001000000000000"; -- range of value destination
--constant r02 : sfixed(entero downto -fraccion) := "0001000000000000"; -- start of range in destination
-- start of range of value to interpol is 0

--signal divmult : sfixed(entero downto -fraccion);
--signal result_mult_sum : sfixed(entero downto -fraccion);

signal m_divmult : signed(2*(entero+fraccion)-1 downto 0);
signal pot_reg : std_logic_vector(entero+fraccion-1 downto 0);
signal divmult, divmult_tmp, result_mult_sum : signed(entero+fraccion-1 downto 0);
signal valid_prop_reg : std_logic;

constant one : std_logic_vector(entero+fraccion-1 downto 0) := (fraccion => '1', others => '0');

begin

--interpol as div&sum   + addition

m_divmult <= signed(pot) * INTERP_1;
divmult_tmp <= m_divmult(2*fraccion+entero-1 downto fraccion);
--divmult <= resize (                                                                 
--               arg => delta2div1 * to_sfixed(pot,entero,-fraccion),
--               size_res => divmult,                                                 
--               overflow_style => fixed_saturate,                                  
--               -- fixed_wrap                                                      
--               round_style => fixed_truncate                                         
--               -- fixed_truncate                                                  
--                );

result_mult_sum <= divmult + INTERP_0;
--result_mult_sum <= resize (                                                                 
--               arg => divmult + r02,
--               size_res => result_mult_sum,                                                 
--               overflow_style => fixed_wrap,                                  
--               -- fixed_wrap                                                      
--               round_style => fixed_truncate                                         
--               -- fixed_truncate                                                  
--                );
                
interpol: process(clk, rst) begin
    if(rst = '0') then
        valid_prop_reg <= '0';
        valid_prop <= '0';
        pot_reg <= (others => '0');
        divmult <= (others => '0');
        inter_result <= (others => '0');
    elsif (clk'event and clk='1') then
        valid_prop_reg <= valid_in;
        valid_prop <= valid_prop_reg;
        pot_reg <= pot;
        divmult <= divmult_tmp;
        -- if bigger than origin interpol range, max destin,or forget it?
        if signed(pot_reg) >= MAX_INTERP then --2.781="0010110001111111" 4.781="0100110001111111"
            inter_result <= one; -- if it's bigger than destine, forget about it.
        elsif(pot_reg(entero+fraccion-1) = '1') then -- si es minus
            inter_result <= one; --1/1 para hacer 400/1
        else
            inter_result <= std_logic_vector(result_mult_sum); --falta por tomar en cuenta si sale del rango primero!
        end if;
    end if;
end process;

end Behavioral;
