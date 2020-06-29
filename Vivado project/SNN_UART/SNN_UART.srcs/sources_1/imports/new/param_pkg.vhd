LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.function_pkg.all;
use work.log2_pkg.all;

package param_pkg is

    constant INT_QUANT :    integer := 8;                                               -- Fixed-point number of integer bits for data in LIF and STDP
    constant FRAC_QUANT :   integer := 16;                                              -- Fixed-point number of fractional bits for data in LIF and STDP
    constant WEIGHT_QUANT : integer := INT_QUANT + FRAC_QUANT;                          -- Fixed-point total number of bits for data in LIF and STDP
    constant TAU :          integer := 6;                                               -- Value of positive and negative taus in STDP
    constant T_BACK :       integer := 20;                                              -- Number of past simulation steps taken into account in STDP
    constant SYN_REC :      signed(WEIGHT_QUANT-1 downto 0) := "00000000" & "00000000" & "00000001"; -- Quantity added in STDP to avoid silent neurons
    constant W_max :        signed(WEIGHT_QUANT-1 downto 0) := "00000101" & "00000000" & "00000000"; -- Maximum synaptic weight for a neuron
    constant W_min :        signed(WEIGHT_QUANT-1 downto 0) := "11111011" & "00000000" & "00000000"; -- Minimum synaptic weight for a neuron
    constant V_th :         signed(WEIGHT_QUANT-1 downto 0) := "00000001" & "00000000" & "00000000"; -- Tension of the spiking threshold
    constant V_min :        signed(WEIGHT_QUANT-1 downto 0) := "11111000" & "00000000" & "00000000"; -- Minimum tension allowed for a neuron
    constant Kt :           signed(WEIGHT_QUANT-1 downto 0) := "00000000" & "00101010" & "10101011"; -- Time constant for LIF

    constant TAU_bits :     integer := log2c(TAU);
    constant T_BACK_bits :  integer := log2c(T_BACK);
    constant WEIGHT_bits :  integer := log2c(WEIGHT_QUANT);
    
    constant n_ones_Kt :    integer := ones(to_integer(Kt));                                        -- Number of '1' in Kt
    constant shifts_Kt :    vector_list(n_ones_Kt-1 downto 0) := shifts(to_integer(Kt), n_ones_Kt); -- Shifts to input the barrel shifter for the multiplication by Kt

    subtype item_LUTRAM is signed(WEIGHT_QUANT-1 downto 0);
    type LUTRAM is array(0 to T_BACK) of item_LUTRAM;
    
    subtype WORD is std_logic_vector(WEIGHT_QUANT-1 downto 0);
    type WORD_array is array(integer range <>) of WORD;

    subtype last_spikes is std_logic_vector(T_BACK_bits-1 downto 0);
    type last_spikes_reg is array(integer range <>) of last_spikes;
    

    constant LUTRAM_pos : LUTRAM := (   -- Values of Apos*exp(-?t/tau) from ?t=0 (assigned to no STDP) to ?t=T_BACK
        ("00000000" & "00000000" & "00000000"), 
        ("00000000" & "00010101" & "10101100"),
        ("00000000" & "00010010" & "01011000"),
        ("00000000" & "00001111" & "10000111"),
        ("00000000" & "00001101" & "00100101"),
        ("00000000" & "00001011" & "00100000"),
        ("00000000" & "00001001" & "01101011"),
        ("00000000" & "00000111" & "11111001"),
        ("00000000" & "00000110" & "11000000"),
        ("00000000" & "00000101" & "10110110"),
        ("00000000" & "00000100" & "11010110"),
        ("00000000" & "00000100" & "00011000"),
        ("00000000" & "00000011" & "01110111"),
        ("00000000" & "00000010" & "11101111"),
        ("00000000" & "00000010" & "01111100"),
        ("00000000" & "00000010" & "00011010"),
        ("00000000" & "00000001" & "11000111"),
        ("00000000" & "00000001" & "10000001"),
        ("00000000" & "00000001" & "01000110"),
        ("00000000" & "00000001" & "00010100"),
        ("00000000" & "00000000" & "11101010")
    );

    constant LUTRAM_neg : LUTRAM := (   -- Values of Aneg*exp(-?t/tau) from ?t=0 (assigned to no STDP) to ?t=T_BACK
        ("00000000" & "00000000" & "00000000"), 
        ("11111111" & "11101010" & "01010100"),
        ("11111111" & "11101101" & "10101000"),
        ("11111111" & "11110000" & "01111001"),
        ("11111111" & "11110010" & "11011011"),
        ("11111111" & "11110100" & "11100000"),
        ("11111111" & "11110110" & "10010101"),
        ("11111111" & "11111000" & "00000111"),
        ("11111111" & "11111001" & "01000000"),
        ("11111111" & "11111010" & "01001010"),
        ("11111111" & "11111011" & "00101010"),
        ("11111111" & "11111011" & "11101000"),
        ("11111111" & "11111100" & "10001001"),
        ("11111111" & "11111101" & "00010001"),
        ("11111111" & "11111101" & "10000100"),
        ("11111111" & "11111101" & "11100110"),
        ("11111111" & "11111110" & "00111001"),
        ("11111111" & "11111110" & "01111111"),
        ("11111111" & "11111110" & "10111010"),
        ("11111111" & "11111110" & "11101100"),
        ("11111111" & "11111111" & "00010110")
    );


end param_pkg;

package body param_pkg is

end param_pkg;
