LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.log2_pkg.all;

package function_pkg is
    
    constant INT_QUANT :    integer := 8;                                               -- Fixed-point number of integer bits for data in LIF and STDP
    constant FRAC_QUANT :   integer := 16;                                              -- Fixed-point number of fractional bits for data in LIF and STDP
    constant WEIGHT_QUANT : integer := INT_QUANT + FRAC_QUANT;                          -- Fixed-point total number of bits for data in LIF and STDP
    
    constant WEIGHT_bits :  integer := log2c(WEIGHT_QUANT);
    
    type vector_list is array(integer range <>) of std_logic_vector(WEIGHT_bits-1 downto 0);

    function ones(Kt: integer) return integer;

    function shifts(Kt: integer; n_ones: integer) return vector_list;

end function_pkg;

package body function_pkg is

    function ones(Kt: integer) return integer is
        variable n_ones : integer := 0;
        variable Kt_v : signed(log2c(Kt)-1 downto 0) := to_signed(Kt, log2c(Kt));
    begin
        for i in Kt_v'range loop
            if Kt_v(i) = '1' then
                n_ones := n_ones + 1;
            end if;
        end loop;
        return n_ones;
    end function;

    function shifts(Kt: integer; n_ones: integer) return vector_list is
        variable list : vector_list(n_ones-1 downto 0);
        variable index : integer := 0;
        variable Kt_v : signed(log2c(Kt)-1 downto 0) := to_signed(Kt, log2c(Kt));
    begin
        for i in Kt_v'range loop
            if Kt_v(i) = '1' then
                list(index) := std_logic_vector(to_unsigned(i,WEIGHT_bits));
                index := index + 1;
            end if;
        end loop;
        return list;
    end function;

end function_pkg;