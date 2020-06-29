LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

package int_pkg is

    type int_vector is array(integer range <>) of integer;
    
    function max_int(ints: int_vector) return integer;

end int_pkg;

package body int_pkg is

    function max_int(ints: int_vector) return integer is
        variable max_tmp : integer := 0;
    begin
        for i in ints'range loop
            if ints(i) > max_tmp then max_tmp := ints(i); end if;
        end loop;
        return max_tmp;
    end function;

end int_pkg;