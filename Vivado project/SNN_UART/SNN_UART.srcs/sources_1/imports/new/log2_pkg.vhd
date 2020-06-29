LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

package log2_pkg is
    
    function log2c(n: integer) return integer;
    
    function power2(n : integer) return integer;
    
    function div_ceil(dividend: integer; divisor: integer) return integer;

end log2_pkg;

package body log2_pkg is

    function log2c(n: integer) return integer is
        variable m, p : integer;
    begin
        m := 0;
        p := 1;
        while p < n loop
            m := m + 1;
            p := p * 2;
        end loop;
        return m;
    end log2c;
    
    function power2(n : integer) return integer is
        variable e : integer := 1;
    begin
        for i in 1 to n loop
            e := e * 2;
        end loop;
        return e;
    end power2;
    
    function div_ceil(dividend: integer; divisor: integer) return integer is
        variable result : integer;
        variable remainder : integer;
    begin
        result := dividend / divisor;
        remainder := dividend rem divisor;
        if remainder > 0 then
            result := result + 1;
        end if;
        return result;
    end function;

end log2_pkg;