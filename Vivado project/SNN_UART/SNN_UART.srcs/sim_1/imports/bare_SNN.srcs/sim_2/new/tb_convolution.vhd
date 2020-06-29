LIBRARY STD;
USE STD.textio.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;
USE IEEE.std_logic_textio.all;

use work.rl_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testbech for Iñaki's convolution module
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity tb_convolution is
end tb_convolution;

architecture behaviour of tb_convolution is

    component Convolution
        generic(
            Nbits :     integer;
            entero :    integer;
            fraccion :  integer;
            per_bits :  integer
        );
        port(
            frame :             in std_logic_vector(31 downto 0);
            clk :               in std_logic;
            rst :               in std_logic;
            arrived :           in std_logic;
            valid_posttrain :   out std_logic;
            period :            out std_logic_vector(per_bits-1 downto 0);
            ready :             out std_logic;
            info_out :          out std_logic_vector(15 downto 0)
        );
    end component;
    
    constant period : time := 10 ns;
    constant NBits : integer := 16;
    constant entero : integer := 4;
    constant fraccion : integer := 12;
    
    type sqr_image is array(integer range <>) of std_logic_vector(7 downto 0);
    type mult_results is array(integer range <>) of signed(32 downto 0);
    type conv_terms is array(integer range <>) of signed(NBits-1 downto 0);
    type sca_matrix is array(integer range <>) of signed(23 downto 0);
    signal image : sqr_image(0 to 32*32-1);
    
    constant sca0 : signed(23 downto 0) := "0000" & "0000" & "0001" & "0000" & "0000" & "0000";-- 1
    constant sca1 : signed(23 downto 0) := "0000" & "0000" & "0000" & "1010" & "0000" & "0000";-- 0.625
    constant sca2 : signed(23 downto 0) := "0000" & "0000" & "0000" & "0100" & "0000" & "0000";-- 0.25
    constant sca3 : signed(23 downto 0) := "1111" & "1111" & "1111" & "1100" & "0000" & "0000";-- -0.25
    constant sca4 : signed(23 downto 0) := "1111" & "1111" & "1111" & "1000" & "0000" & "0000";-- -.5
    
    constant sca : sca_matrix(0 to 24) := (sca4, sca3, sca2, sca3, sca4,
                                            sca3, sca2, sca1, sca2, sca3,
                                            sca2, sca1, sca0, sca1, sca2,
                                            sca3, sca2, sca1, sca2, sca3,
                                            sca4, sca3, sca2, sca3, sca4);
                                            
    constant one : std_logic_vector(entero+fraccion-1 downto 0) := (fraccion => '1', others => '0');
    
    signal frame : std_logic_vector(31 downto 0);
    signal clk, reset, arrived, valid_posttrain, ready : std_logic;
    signal period_out : std_logic_vector(MAX_PER_bits-1 downto 0);
    signal period_reg : period_vector(0 to 783);
    signal info_out : std_logic_vector(15 downto 0);
         
begin

    UUT : Convolution
        generic map(
            Nbits =>    NBits,
            entero =>   entero,
            fraccion => fraccion,
            per_bits => MAX_PER_bits
        )
        port map(
            frame =>            frame,
            clk =>              clk,
            rst =>              reset,
            arrived =>          arrived,
            valid_posttrain =>  valid_posttrain,
            period =>           period_out,
            ready =>            ready,
            info_out =>         info_out
        );
        
    proc_clk : process
    begin
        clk <= '0', '1' after period/2;
        wait for period;
    end process;
    
    process
    
        variable rand : real;
        variable seed1, seed2 : positive;
        file f : text;
        variable L : line;
        variable buf : std_logic_vector(7 downto 0);
    
    begin
    
        reset <= '0';   arrived <= '0';    frame <= (others => '0');    image <= (others => (others => '0'));
        
        wait for 5*period;
        reset <= '1';
        wait for period;
            
        file_open(f, "../../../../x_train.txt", read_mode);
        
        for n in 0 to 49 loop
        
            image <= (others => (others => '0'));
            
--            for j in 2 to 32-3 loop     -- Random image generation
--                for i in 2 to 32-3 loop
--                    uniform(seed1,seed2,rand);
--                    image(j*32+i) <= std_logic_vector(to_unsigned(integer(rand*255),8));
--                end loop;
--            end loop;
            
--            -- Image info
--            arrived <= '1';
--            uniform(seed1,seed2,rand);
--            frame <= std_logic_vector(to_unsigned(integer(rand*255),32));
            
            arrived <= '1';
            frame <= (others => '0');
            readline(f,L);
            hread(L, buf);
            frame(7 downto 0) <= buf;
            
            for j in 0 to 31 loop   -- Read image from file
                for i in 0 to 31 loop
                    readline(f,L);
                    hread(L, buf);
                    image(j*32+i) <= buf;
                end loop;
            end loop;

            wait for period;
            
            for j in 2 to 32-3 loop
                for i in 0 to 6 loop
                    for k in 0 to 3 loop
                        frame((3-k)*8+7 downto (3-k)*8) <= image(j*32+(i*4)+2+k);
                    end loop;
                    wait for period;
                end loop;
            end loop;
            
            arrived <= '0';
            
            wait for 800*period;
        
        end loop;
        
        file_close(f);
    
        assert false report "FIN" severity failure;
        
    end process;
    
    check_proc : process(clk, valid_posttrain)
        variable pix_num, idx_x, idx_y : natural := 0;
        variable conv_pixels : sqr_image(0 to 24);
        variable mult : mult_results(0 to 24);
        variable terms : conv_terms(0 to 24);
        variable sum : signed(NBits-1 downto 0);
        variable interp_res : unsigned(NBits-1 downto 0);
        variable interp_mult : signed(2*Nbits-1 downto 0);
        variable freq_mult : unsigned(BITS_FREQ+NBits-1 downto 0);
        variable frequency : unsigned(BITS_FREQ-1 downto 0);
        variable period_res : std_logic_vector(MAX_PER_bits-1 downto 0) := std_logic_vector(to_unsigned(405,MAX_PER_bits));
    begin
        
        if (clk'event and clk = '0' and valid_posttrain = '1') then
            
            idx_y := pix_num / 28;  idx_x := pix_num rem 28;
            for j in 0 to 4 loop
                for i in 0 to 4 loop
                    conv_pixels(j*5+i) := image((idx_y+j)*32 + idx_x+i);
                end loop;
            end loop;
            sum := (others => '0');
            for i in 0 to 24 loop
                mult(i) := signed('0' & conv_pixels(i)) * sca(i);
                terms(i) := mult(i)(fraccion+INT_INTERP+8-1 downto 8);
                sum := sum + terms(i);
            end loop;
            if sum >= MAX_INTERP or sum(NBits-1) = '1' then
                interp_mult := (others => '0');
                interp_res := unsigned(one);
            else  
                interp_mult := sum * INTERP_1;
                interp_res := unsigned(std_logic_vector(interp_mult(2*fraccion+entero-1 downto fraccion))) + unsigned(std_logic_vector(INTERP_0));            
            end if;
            freq_mult := interp_res * AUX_STEPS_INV;
            frequency := freq_mult(BITS_FREQ+fraccion-1 downto fraccion);
            if to_integer(frequency) >= MIN_FREQ and to_integer(frequency) <= MAX_FREQ then
                period_res := std_logic_vector(to_unsigned(period_LUT(to_integer(frequency)),MAX_PER_bits));
            else
                period_res := std_logic_vector(to_unsigned(STEPS,MAX_PER_bits));
            end if;
            
            assert period_out = period_res report "Wrong period calculation" severity error;
            period_reg(pix_num) <= unsigned(period_out);
            
            if pix_num < 783 then
                pix_num := pix_num + 1;
            else
                pix_num := 0;
            end if;
        end if;
        
    end process;

end behaviour;