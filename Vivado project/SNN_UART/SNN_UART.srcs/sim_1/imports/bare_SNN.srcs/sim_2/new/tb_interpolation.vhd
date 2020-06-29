LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.param_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for Iñaki's interpolator
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_interpolation is
end tb_interpolation;

architecture behaviour of tb_interpolation is

   component interpolation is
        Generic ( entero: integer; fraccion: integer);
        Port ( pot : in STD_LOGIC_VECTOR (entero+fraccion-1 downto 0);
               clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               valid_in : in STD_LOGIC;
               valid_prop : out STD_LOGIC;
               inter_result : out STD_LOGIC_VECTOR (entero+fraccion-1 downto 0));
   end component;
   
   constant period : time := 10 ns;
   constant entero : integer := 4;
   constant fraccion : integer := 12;
   
   signal clk, reset, valid_in, valid_prop : std_logic;
   signal pot, inter_result : std_logic_vector(entero+fraccion-1 downto 0);

begin

    UUT : interpolation
        generic map(
            entero =>   entero,
            fraccion => fraccion
        )
        port map(
           pot =>           pot,
           clk =>           clk,
           rst =>           reset,
           valid_in =>      valid_in,
           valid_prop =>    valid_prop,
           inter_result =>  inter_result
        );

    proc_clk : process
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    process
    
        variable rand : real;
        variable seed1, seed2 : positive;
    
    begin
        
        reset <= '0';   valid_in <= '0';    pot <= (others => '0');
       
        wait for 5*period; 
        reset <= '1';
        wait for period;
        
        valid_in <= '1';
        
        for i in 0 to 499 loop
            uniform(seed1,seed2,rand);
            pot <= std_logic_vector(to_unsigned(integer(rand*65535),entero+fraccion));
            
            wait for period;
        end loop;
        
        valid_in <= '0';
        wait for 2*period;
        
        assert false report "FIN" severity failure;
        
    end process;

end behaviour;