----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.02.2019 10:39:03
-- Design Name: 
-- Module Name: kernel_mult - Behavioral
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


entity kernel_mult is
    Generic (NBits: integer:= 16; entero: integer:= 4; fraccion: integer:= 12);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           pixels25 : in STD_LOGIC_VECTOR (199 downto 0);
           valid_in : in STD_LOGIC;
           valid_prop : out STD_LOGIC;
           multiplied : out STD_LOGIC_VECTOR (399 downto 0));
end kernel_mult;

architecture Behavioral of kernel_mult is
    
    constant sca0 : signed(NBits-1 downto 0) := "0001" & "0000" & "0000" & "0000";-- 1
    constant sca1 : signed(NBits-1 downto 0) := "0000" & "1010" & "0000" & "0000";-- 0.625
    constant sca2 : signed(NBits-1 downto 0) := "0000" & "0100" & "0000" & "0000";-- 0.25
    constant sca3 : signed(NBits-1 downto 0) := "1111" & "1100" & "0000" & "0000";-- -0.25
    constant sca4 : signed(NBits-1 downto 0) := "1111" & "1000" & "0000" & "0000";-- -.5
    
    signal   mult0, mult1, mult2, mult3, mult4: signed(NBits+8 downto 0);
    signal   mult5, mult6, mult7, mult8, mult9: signed(NBits+8 downto 0);
    signal   mult10, mult11, mult12, mult13, mult14: signed(NBits+8 downto 0);
    signal   mult15, mult16, mult17, mult18, mult19: signed(NBits+8 downto 0);
    signal   mult20, mult21, mult22, mult23, mult24: signed(NBits+8 downto 0);
    
    type factors is array(integer range <>) of signed(8 downto 0);
    
    signal fact : factors(24 downto 0);
  
begin

    parallel_multiplications: process(clk,rst)
    begin
        if rst = '0' then
            valid_prop <= '0';
            multiplied <= (others => '0');
        elsif clk'event and clk = '1' then
            valid_prop <= valid_in;
            multiplied(399 downto 384) <= std_logic_vector(mult0(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(383 downto 368) <= std_logic_vector(mult1(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(367 downto 352) <= std_logic_vector(mult2(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(351 downto 336) <= std_logic_vector(mult3(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(335 downto 320) <= std_logic_vector(mult4(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(319 downto 304) <= std_logic_vector(mult5(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(303 downto 288) <= std_logic_vector(mult6(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(287 downto 272) <= std_logic_vector(mult7(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(271 downto 256) <= std_logic_vector(mult8(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(255 downto 240) <= std_logic_vector(mult9(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(239 downto 224) <= std_logic_vector(mult10(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(223 downto 208) <= std_logic_vector(mult11(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(207 downto 192) <= std_logic_vector(mult12(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(191 downto 176) <= std_logic_vector(mult13(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(175 downto 160) <= std_logic_vector(mult14(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(159 downto 144) <= std_logic_vector(mult15(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(143 downto 128) <= std_logic_vector(mult16(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(127 downto 112) <= std_logic_vector(mult17(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(111 downto 96) <= std_logic_vector(mult18(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(95 downto 80) <= std_logic_vector(mult19(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(79 downto 64) <= std_logic_vector(mult20(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(63 downto 48) <= std_logic_vector(mult21(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(47 downto 32) <= std_logic_vector(mult22(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(31 downto 16) <= std_logic_vector(mult23(fraccion+INT_INTERP+8-1 downto 8));
            multiplied(15 downto 0) <= std_logic_vector(mult24(fraccion+INT_INTERP+8-1 downto 8));
        end if;
    end process;

        mult0 <= sca4 * fact(0);
        mult1 <= sca3 * fact(1);
        mult2 <= sca2 * fact(2);  
        mult3 <= sca3 * fact(3);                                                           
        mult4 <= sca4 * fact(4);
        mult5 <= sca3 * fact(5);
        mult6 <= sca2 * fact(6);
        mult7 <= sca1 * fact(7);
        mult8 <= sca2 * fact(8);
        mult9 <= sca3 * fact(9);
        mult10 <= sca2 * fact(10);
        mult11 <= sca1 * fact(11);
        mult12 <= sca0 * fact(12);
        mult13 <= sca1 * fact(13);
        mult14 <= sca2 * fact(14);
        mult15 <= sca3 * fact(15);
        mult16 <= sca2 * fact(16);
        mult17 <= sca1 * fact(17);
        mult18 <= sca2 * fact(18);
        mult19 <= sca3 * fact(19);
        mult20 <= sca4 * fact(20);
        mult21 <= sca3 * fact(21);
        mult22 <= sca2 * fact(22);
        mult23 <= sca3 * fact(23);
        mult24 <= sca4 * fact(24);

    process(pixels25)
    begin
        BIT_EXT : for i in 0 to 24 loop
            fact(i)(8) <= '0';
            fact(i)(7 downto 0) <= signed(pixels25((24-i)*8+7 downto (24-i)*8));
        end loop;
    end process;

end Behavioral;
