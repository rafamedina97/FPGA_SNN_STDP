----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.02.2019 12:27:52
-- Design Name: 
-- Module Name: Sum - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Sum is
    generic (NBits: integer := 16; entero: integer := 4; fraccion: integer :=12);
    Port ( Clk : in STD_LOGIC;
           Reset : in STD_LOGIC;
           Var0 : in STD_LOGIC_VECTOR (NBits-1 downto 0);
           Var1 : in STD_LOGIC_VECTOR (NBits-1 downto 0);
           VarOut : out STD_LOGIC_VECTOR (NBits-1 downto 0));
end Sum;

architecture Behavioral of Sum is

--signal summed : sfixed (entero downto -fraccion);
--signal Var0_internal : sfixed (entero downto -fraccion);
--signal Var1_internal : sfixed (entero downto -fraccion);

signal summed : std_logic_vector(NBits-1 downto 0);

begin

--    VarOut <= to_slv(summed);
--    Var0_internal <= to_sfixed(Var0, Var0_internal);
--    Var1_internal <= to_sfixed(Var1, Var1_internal

    VarOut <= summed;

    process(clk,reset) begin
    
        if(reset = '0') then
            summed <= (others => '0');
        elsif(clk'event and clk='1') then
            summed <= std_logic_vector(signed(Var0) + signed(Var1));
--            summed <= resize (
--                        arg => Var0_internal + Var1_internal,
--                        size_res => Var0_internal,
--                        overflow_style => fixed_saturate,
--                        -- fixed_wrap
--                        round_style => fixed_round
--                        -- fixed_truncate
--                          );
         end if;
    end process;

end Behavioral;
