LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.log2_pkg.all;
use work.syn_mem_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAM memory for storing the synaptic weights for the neuron, with simultaneous input and output
------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
entity synaptic_mem is
    generic(
        PREV_LAYER_NEURONS :    integer;
        LAYER :                 integer;
        NEURON :                integer
    );
    port(
            clka :  IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(log2c(PREV_LAYER_NEURONS)-1 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(WEIGHT_QUANT-1 DOWNTO 0);
            clkb :  IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(log2c(PREV_LAYER_NEURONS)-1 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(WEIGHT_QUANT-1 DOWNTO 0)
    );
end synaptic_mem;

architecture behaviour of synaptic_mem is

    signal RAM : WORD_array(PREV_LAYER_NEURONS-1 downto 0) := ini_syn_ram(PREV_LAYER_NEURONS, LAYER, NEURON);
    signal out_buffer : std_logic_vector(WEIGHT_QUANT-1 downto 0) := (others => '0');

begin

    process(clka)
    begin
        if clka'event and clka = '1' then
            if wea = "1" then
                RAM(to_integer(unsigned(addra))) <= dina;
            end if;
            
            out_buffer <= RAM(to_integer(unsigned(addrb)));
            doutb <= out_buffer;
        end if;
    end process;

end behaviour;
