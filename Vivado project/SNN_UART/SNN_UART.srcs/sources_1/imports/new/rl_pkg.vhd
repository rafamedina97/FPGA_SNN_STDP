LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.log2_pkg.all;

package rl_pkg is

    constant INT_INTERP :       integer :=                          4;                          -- Integer bits of the signals in the interpolation
    constant FRAC_INTERP :      integer :=                          12;                         -- Fractional bits of the signals in the interpolation
    constant BITS_INTERP :      integer :=                          INT_INTERP + FRAC_INTERP;   -- Quantization bits of the signals in the interpolation
    constant INTERP_1 :         signed(BITS_INTERP-1 downto 0) :=   "00010100" & "00000000";    -- 1st-degree term of the interpolation (5/4)
    constant INTERP_0 :         signed(BITS_INTERP-1 downto 0) :=   "00010000" & "00000000";    -- 0-degree term of the interpolation (1)
    constant MAX_INTERP :       signed(BITS_INTERP-1 downto 0) :=   "01000000" & "00000000";    -- Maximum input to the interpolation
    constant BITS_FREQ :        integer :=                          16;                         -- Quantization bits for the frequency calculation
    constant STEPS :            integer :=                          400;                        -- Number of simulation steps 
    constant AUX_STEPS :        integer :=                          490;                        -- Auxiliar number of simulation steps for frequency computing 
    constant AUX_STEPS_INV :    unsigned(BITS_FREQ-1 downto 0) :=   "00000000" & "01000010";    -- Inverse of the auxiliar number of sim steps (1/490 representing 1/400)
    constant BITS_PER_LUT :     integer :=                          9;                          -- Bits needed to represent all the resulting frequencies and address the period LUT
    constant MIN_FREQ :         integer :=                          65;                         -- Minimum result of the frequency multiplication    
    constant MAX_FREQ :         integer :=                          401;                        -- Maximum result of the frequency multiplication 
    constant MAX_PER :          integer :=                          400;                        -- Maximum period for the input neuron counters
    
    constant STEPS_bits :       integer :=  log2c(STEPS);
    constant MAX_PER_bits :     integer :=  log2c(MAX_PER);
    
    type LUT_periods is array(integer range <>) of std_logic_vector(MAX_PER_bits-1 downto 0);
    
    subtype period is unsigned(MAX_PER_bits-1 downto 0);
    type period_vector is array(integer range <>) of period;
    
    function period_LUT(x : integer) return integer;
    
    function LUT_init(min_value : integer; max_value : integer) return LUT_periods;
    
end rl_pkg;

package body rl_pkg is
    
    function period_LUT(x : integer) return integer is
        variable tmp : real;
        variable y : integer;
    begin
        tmp := real(x) * real(AUX_STEPS);
        tmp := tmp / real(power2(BITS_FREQ-1));
        tmp := 1.0 / tmp;
        y := integer(tmp * real(STEPS));
        return y;
    end period_LUT;
    
    function LUT_init(min_value : integer; max_value : integer) return LUT_periods is
        variable lut : LUT_periods(min_value to max_value);
    begin
        for i in min_value to max_value loop
            lut(i) := std_logic_vector(to_unsigned(period_LUT(i), MAX_PER_bits));
        end loop;
        return lut;
    end LUT_init;
    
end rl_pkg;