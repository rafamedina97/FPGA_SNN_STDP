LIBRARY STD;
USE STD.textio.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_textio.all;

use work.param_pkg.all;

package syn_mem_pkg is
    
    impure function ini_syn_ram(length : integer; layer : integer; neuron : integer) return WORD_array;
    
end syn_mem_pkg;

package body syn_mem_pkg is

    impure function ini_syn_ram(length : integer; layer : integer; neuron : integer) return WORD_array is
        --constant filename : string := "../../../../weights/neuron_"&integer'image(layer)&"_"&integer'image(neuron)&".txt";    -- For simulation
        --constant filename : string := "../../weights/neuron_"&integer'image(layer)&"_"&integer'image(neuron)&".txt";    -- For synthesis
        constant filename : string := "C:/Users/rafam/VivadoProjects/bare_SNN/weights/neuron_"&integer'image(layer)&"_"&integer'image(neuron)&".txt";
        file f : text;
        variable contents : WORD_array(length-1 downto 0);
        variable L : line;
    begin
        file_open(f, filename, read_mode);
        for i in 0 to length-1 loop
            readline(f,L);
            hread(L,contents(i));
        end loop;
        file_close(f);
        return contents;
    end function;

end syn_mem_pkg;