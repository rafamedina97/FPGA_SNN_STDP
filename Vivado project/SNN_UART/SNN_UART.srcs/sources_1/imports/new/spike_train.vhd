----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.03.2019 12:40:13
-- Design Name: 
-- Module Name: spike_train - Behavioral
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

use work.rl_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spike_train is
    Generic ( entero: integer:= 4; fraccion: integer:= 12);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid_in : in std_logic;
           valid_out : out std_logic;
           intensity : in STD_LOGIC_VECTOR (entero+fraccion-1 downto 0);
           period : out std_logic_vector (MAX_PER_bits-1 downto 0));
end spike_train;

architecture Behavioral of spike_train is

signal lut : LUT_periods(MIN_FREQ to MAX_FREQ) := LUT_init(MIN_FREQ, MAX_FREQ);

signal frequency : unsigned(BITS_FREQ-1 downto 0);
signal mult_res : unsigned(BITS_FREQ+entero+fraccion-1 downto 0);
--signal frequency : sfixed(0 downto -15);
--constant simul_time_inv : sfixed(0 downto -15) :="0000000001000010"; -- 1/490 *2^15 = 0.00204081632 *2^15 = 66.87
--sfixed(0 downto -18) := "0000000001010001111";--1/400 * 2^18
-- constant simul_time_inv : sfixed(0 downto -15) :="0000000001000010"; -- 1/490 *2^15 = 0.00204081632 *2^15 = 66.87
--"0000000001111000";-- 1/490 * 317/177 = 0.003655 -->  120 en binario
--
--"0000000001010010"; -- (1/400) -> 81.92 *2^-15
--frecuencias iran= 82,83,84,85...491
-- en vez de 1/400 tiene que ser 1/490. Porque la division de 400/1 a 400/6 tiene 335 enteros! 335 frecuencias diferentes.

signal valid_mult : std_logic;

begin

mult_res <= AUX_STEPS_INV * unsigned(intensity);

freqmult: process(clk, rst) begin
    if(rst='0') then
        frequency <= (others => '0');
        valid_mult <= '0';
    elsif(clk'event and clk='1') then
        frequency <= mult_res(BITS_FREQ+fraccion-1 downto fraccion);
--        frequency <= resize (                                                                 
--                   arg => simul_time_inv * to_sfixed(intensity,entero,-fraccion),
--                   size_res => simul_time_inv,                                                 
--                   overflow_style => fixed_wrap,                                  
--                   -- fixed_wrap                                                      
--                   round_style => fixed_truncate                                         
--                   -- fixed_truncate                                                  
--                    );
        valid_mult <= valid_in;
     end if;
end process;

freqlut: process(clk, rst) begin
    if(rst='0') then
        valid_out <= '0';
        period <= (others => '0');
    elsif (clk'event and clk='1') then
        valid_out <= valid_mult;
        if (to_integer(unsigned(frequency)) >= MIN_FREQ and to_integer(unsigned(frequency)) <= MAX_FREQ) then
            period <= lut(to_integer(unsigned(frequency)));
        else
            period <= std_logic_vector(to_unsigned(STEPS, MAX_PER_bits));
        end if;
--        case(to_integer(unsigned(to_slv(frequency(-7 downto -15))))) is --8 downto 0 covers all these values.
--       when 65  => period <=std_logic_vector(to_unsigned(400,16));
 
--        when 66  => period <=std_logic_vector(to_unsigned(400,16));
--        when 67  => period <=std_logic_vector(to_unsigned(395,16));
--        when 68  => period <=std_logic_vector(to_unsigned(390,16));
--        when 69  => period <=std_logic_vector(to_unsigned(384,16));
--        when 70  => period <=std_logic_vector(to_unsigned(379,16));
--        when 71  => period <=std_logic_vector(to_unsigned(374,16));
--        when 72  => period <=std_logic_vector(to_unsigned(369,16));
--        when 73  => period <=std_logic_vector(to_unsigned(365,16));
--        when 74  => period <=std_logic_vector(to_unsigned(360,16));
--        when 75  => period <=std_logic_vector(to_unsigned(356,16));
--        when 76  => period <=std_logic_vector(to_unsigned(351,16));
--        when 77  => period <=std_logic_vector(to_unsigned(347,16));
--        when 78  => period <=std_logic_vector(to_unsigned(343,16));
--        when 79  => period <=std_logic_vector(to_unsigned(339,16));
--        when 80  => period <=std_logic_vector(to_unsigned(335,16));
--        when 81  => period <=std_logic_vector(to_unsigned(327,16));
--        when 82  => period <=std_logic_vector(to_unsigned(323,16));
--        when 83  => period <=std_logic_vector(to_unsigned(320,16));
--        when 84  => period <=std_logic_vector(to_unsigned(316,16));
--        when 85  => period <=std_logic_vector(to_unsigned(313,16));
--        when 86  => period <=std_logic_vector(to_unsigned(309,16));
--        when 87  => period <=std_logic_vector(to_unsigned(306,16));
--        when 88  => period <=std_logic_vector(to_unsigned(303,16));
--        when 89  => period <=std_logic_vector(to_unsigned(300,16));
--        when 90  => period <=std_logic_vector(to_unsigned(297,16));
--        when 91  => period <=std_logic_vector(to_unsigned(294,16));
--        when 92  => period <=std_logic_vector(to_unsigned(291,16));
--        when 93  => period <=std_logic_vector(to_unsigned(288,16));
--        when 94  => period <=std_logic_vector(to_unsigned(285,16));
--        when 95  => period <=std_logic_vector(to_unsigned(282,16));
--        when 96  => period <=std_logic_vector(to_unsigned(276,16));
--        when 97  => period <=std_logic_vector(to_unsigned(274,16));
--        when 98  => period <=std_logic_vector(to_unsigned(271,16));
--        when 99  => period <=std_logic_vector(to_unsigned(269,16));
--        when 100 => period <=std_logic_vector(to_unsigned(266,16));
--        when 101 => period <=std_logic_vector(to_unsigned(264,16));
--        when 102 => period <=std_logic_vector(to_unsigned(261,16));
--        when 103 => period <=std_logic_vector(to_unsigned(259,16));
--        when 104 => period <=std_logic_vector(to_unsigned(257,16));
--        when 105 => period <=std_logic_vector(to_unsigned(254,16));
--        when 106 => period <=std_logic_vector(to_unsigned(252,16));
--        when 107 => period <=std_logic_vector(to_unsigned(250,16));
--        when 108 => period <=std_logic_vector(to_unsigned(248,16));
--        when 109 => period <=std_logic_vector(to_unsigned(246,16));
--        when 110 => period <=std_logic_vector(to_unsigned(244,16));
--        when 111 => period <=std_logic_vector(to_unsigned(241,16));
--        when 112 => period <=std_logic_vector(to_unsigned(237,16));
--        when 113 => period <=std_logic_vector(to_unsigned(235,16));
--        when 114 => period <=std_logic_vector(to_unsigned(234,16));
--        when 115 => period <=std_logic_vector(to_unsigned(232,16));
--        when 116 => period <=std_logic_vector(to_unsigned(230,16));
--        when 117 => period <=std_logic_vector(to_unsigned(228,16));
--        when 118 => period <=std_logic_vector(to_unsigned(226,16));
--        when 119 => period <=std_logic_vector(to_unsigned(224,16));
--        when 120 => period <=std_logic_vector(to_unsigned(223,16));
--        when 121 => period <=std_logic_vector(to_unsigned(221,16));
--        when 122 => period <=std_logic_vector(to_unsigned(219,16));
--        when 123 => period <=std_logic_vector(to_unsigned(218,16));
--        when 124 => period <=std_logic_vector(to_unsigned(216,16));
--        when 125 => period <=std_logic_vector(to_unsigned(214,16));
--        when 126 => period <=std_logic_vector(to_unsigned(213,16));
--        when 127 => period <=std_logic_vector(to_unsigned(210,16));
--        when 128 => period <=std_logic_vector(to_unsigned(208,16));
--        when 129 => period <=std_logic_vector(to_unsigned(207,16));
--        when 130 => period <=std_logic_vector(to_unsigned(205,16));
--        when 131 => period <=std_logic_vector(to_unsigned(204,16));
--        when 132 => period <=std_logic_vector(to_unsigned(202,16));
--        when 133 => period <=std_logic_vector(to_unsigned(201,16));
--        when 134 => period <=std_logic_vector(to_unsigned(199,16));
--        when 135 => period <=std_logic_vector(to_unsigned(198,16));
--        when 136 => period <=std_logic_vector(to_unsigned(197,16));
--        when 137 => period <=std_logic_vector(to_unsigned(195,16));
--        when 138 => period <=std_logic_vector(to_unsigned(194,16));
--        when 139 => period <=std_logic_vector(to_unsigned(193,16));
--        when 140 => period <=std_logic_vector(to_unsigned(191,16));
--        when 141 => period <=std_logic_vector(to_unsigned(190,16));
--        when 142 => period <=std_logic_vector(to_unsigned(189,16));
--        when 143 => period <=std_logic_vector(to_unsigned(186,16));
--        when 144 => period <=std_logic_vector(to_unsigned(185,16));
--        when 145 => period <=std_logic_vector(to_unsigned(184,16));
--        when 146 => period <=std_logic_vector(to_unsigned(183,16));
--        when 147 => period <=std_logic_vector(to_unsigned(182,16));
--        when 148 => period <=std_logic_vector(to_unsigned(181,16));
--        when 149 => period <=std_logic_vector(to_unsigned(179,16));
--        when 150 => period <=std_logic_vector(to_unsigned(178,16));
--        when 151 => period <=std_logic_vector(to_unsigned(177,16));
--        when 152 => period <=std_logic_vector(to_unsigned(176,16));
--        when 153 => period <=std_logic_vector(to_unsigned(175,16));
--        when 154 => period <=std_logic_vector(to_unsigned(174,16));
--        when 155 => period <=std_logic_vector(to_unsigned(173,16));
--        when 156 => period <=std_logic_vector(to_unsigned(172,16));
--        when 157 => period <=std_logic_vector(to_unsigned(171,16));
--        when 158 => period <=std_logic_vector(to_unsigned(169,16));
--        when 159 => period <=std_logic_vector(to_unsigned(168,16));
--        when 160 => period <=std_logic_vector(to_unsigned(167,16));
--        when 161 => period <=std_logic_vector(to_unsigned(166,16));
--        when 162 => period <=std_logic_vector(to_unsigned(165,16));
--        when 163 => period <=std_logic_vector(to_unsigned(164,16));
--        when 164 => period <=std_logic_vector(to_unsigned(163,16));
--        when 165 => period <=std_logic_vector(to_unsigned(162,16));
--        when 166 => period <=std_logic_vector(to_unsigned(161,16));
--        when 167 => period <=std_logic_vector(to_unsigned(160,16));
--        when 168 => period <=std_logic_vector(to_unsigned(159,16));
--        when 169 => period <=std_logic_vector(to_unsigned(159,16));
--        when 170 => period <=std_logic_vector(to_unsigned(158,16));
--        when 171 => period <=std_logic_vector(to_unsigned(157,16));
--        when 172 => period <=std_logic_vector(to_unsigned(156,16));
--        when 173 => period <=std_logic_vector(to_unsigned(155,16));
--        when 174 => period <=std_logic_vector(to_unsigned(153,16));
--        when 175 => period <=std_logic_vector(to_unsigned(153,16));
--        when 176 => period <=std_logic_vector(to_unsigned(152,16));
--        when 177 => period <=std_logic_vector(to_unsigned(151,16));
--        when 178 => period <=std_logic_vector(to_unsigned(150,16));
--        when 179 => period <=std_logic_vector(to_unsigned(149,16));
--        when 180 => period <=std_logic_vector(to_unsigned(149,16));
--        when 181 => period <=std_logic_vector(to_unsigned(148,16));
--        when 182 => period <=std_logic_vector(to_unsigned(147,16));
--        when 183 => period <=std_logic_vector(to_unsigned(146,16));
--        when 184 => period <=std_logic_vector(to_unsigned(146,16));
--        when 185 => period <=std_logic_vector(to_unsigned(145,16));
--        when 186 => period <=std_logic_vector(to_unsigned(144,16));
--        when 187 => period <=std_logic_vector(to_unsigned(143,16));
--        when 188 => period <=std_logic_vector(to_unsigned(143,16));
--        when 189 => period <=std_logic_vector(to_unsigned(141,16));
--        when 190 => period <=std_logic_vector(to_unsigned(141,16));
--        when 191 => period <=std_logic_vector(to_unsigned(140,16));
--        when 192 => period <=std_logic_vector(to_unsigned(139,16));
--        when 193 => period <=std_logic_vector(to_unsigned(139,16));
--        when 194 => period <=std_logic_vector(to_unsigned(138,16));
--        when 195 => period <=std_logic_vector(to_unsigned(137,16));
--        when 196 => period <=std_logic_vector(to_unsigned(137,16));
--        when 197 => period <=std_logic_vector(to_unsigned(136,16));
--        when 198 => period <=std_logic_vector(to_unsigned(135,16));
--        when 199 => period <=std_logic_vector(to_unsigned(135,16));
--        when 200 => period <=std_logic_vector(to_unsigned(134,16));
--        when 201 => period <=std_logic_vector(to_unsigned(133,16));
--        when 202 => period <=std_logic_vector(to_unsigned(133,16));
--        when 203 => period <=std_logic_vector(to_unsigned(132,16));
--        when 204 => period <=std_logic_vector(to_unsigned(132,16));
--        when 205 => period <=std_logic_vector(to_unsigned(130,16));
--        when 206 => period <=std_logic_vector(to_unsigned(130,16));
--        when 207 => period <=std_logic_vector(to_unsigned(129,16));
--        when 208 => period <=std_logic_vector(to_unsigned(129,16));
--        when 209 => period <=std_logic_vector(to_unsigned(128,16));
--        when 210 => period <=std_logic_vector(to_unsigned(128,16));
--        when 211 => period <=std_logic_vector(to_unsigned(127,16));
--        when 212 => period <=std_logic_vector(to_unsigned(126,16));
--        when 213 => period <=std_logic_vector(to_unsigned(126,16));
--        when 214 => period <=std_logic_vector(to_unsigned(125,16));
--        when 215 => period <=std_logic_vector(to_unsigned(125,16));
--        when 216 => period <=std_logic_vector(to_unsigned(124,16));
--        when 217 => period <=std_logic_vector(to_unsigned(124,16));
--        when 218 => period <=std_logic_vector(to_unsigned(123,16));
--        when 219 => period <=std_logic_vector(to_unsigned(123,16));
--        when 220 => period <=std_logic_vector(to_unsigned(122,16));
--        when 221 => period <=std_logic_vector(to_unsigned(121,16));
--        when 222 => period <=std_logic_vector(to_unsigned(121,16));
--        when 223 => period <=std_logic_vector(to_unsigned(120,16));
--        when 224 => period <=std_logic_vector(to_unsigned(120,16));
--        when 225 => period <=std_logic_vector(to_unsigned(119,16));
--        when 226 => period <=std_logic_vector(to_unsigned(119,16));
--        when 227 => period <=std_logic_vector(to_unsigned(118,16));
--        when 228 => period <=std_logic_vector(to_unsigned(118,16));
--        when 229 => period <=std_logic_vector(to_unsigned(117,16));
--        when 230 => period <=std_logic_vector(to_unsigned(117,16));
--        when 231 => period <=std_logic_vector(to_unsigned(116,16));
--        when 232 => period <=std_logic_vector(to_unsigned(116,16));
--        when 233 => period <=std_logic_vector(to_unsigned(115,16));
--        when 234 => period <=std_logic_vector(to_unsigned(115,16));
--        when 235 => period <=std_logic_vector(to_unsigned(114,16));
--        when 236 => period <=std_logic_vector(to_unsigned(113,16));
--        when 237 => period <=std_logic_vector(to_unsigned(113,16));
--        when 238 => period <=std_logic_vector(to_unsigned(113,16));
--        when 239 => period <=std_logic_vector(to_unsigned(112,16));
--        when 240 => period <=std_logic_vector(to_unsigned(112,16));
--        when 241 => period <=std_logic_vector(to_unsigned(111,16));
--        when 242 => period <=std_logic_vector(to_unsigned(111,16));
--        when 243 => period <=std_logic_vector(to_unsigned(110,16));
--        when 244 => period <=std_logic_vector(to_unsigned(110,16));
--        when 245 => period <=std_logic_vector(to_unsigned(110,16));
--        when 246 => period <=std_logic_vector(to_unsigned(109,16));
--        when 247 => period <=std_logic_vector(to_unsigned(109,16));
--        when 248 => period <=std_logic_vector(to_unsigned(108,16));
--        when 249 => period <=std_logic_vector(to_unsigned(108,16));
--        when 250 => period <=std_logic_vector(to_unsigned(107,16));
--        when 251 => period <=std_logic_vector(to_unsigned(107,16));
--        when 252 => period <=std_logic_vector(to_unsigned(106,16));
--        when 253 => period <=std_logic_vector(to_unsigned(106,16));
--        when 254 => period <=std_logic_vector(to_unsigned(106,16));
--        when 255 => period <=std_logic_vector(to_unsigned(105,16));
--        when 256 => period <=std_logic_vector(to_unsigned(105,16));
--        when 257 => period <=std_logic_vector(to_unsigned(104,16));
--        when 258 => period <=std_logic_vector(to_unsigned(104,16));
--        when 259 => period <=std_logic_vector(to_unsigned(104,16));
--        when 260 => period <=std_logic_vector(to_unsigned(103,16));
--        when 261 => period <=std_logic_vector(to_unsigned(103,16));
--        when 262 => period <=std_logic_vector(to_unsigned(103,16));
--        when 263 => period <=std_logic_vector(to_unsigned(102,16));
--        when 264 => period <=std_logic_vector(to_unsigned(102,16));
--        when 265 => period <=std_logic_vector(to_unsigned(101,16));
--        when 266 => period <=std_logic_vector(to_unsigned(101,16));
--        when 267 => period <=std_logic_vector(to_unsigned(100,16));
--        when 268 => period <=std_logic_vector(to_unsigned(100,16));
--        when 269 => period <=std_logic_vector(to_unsigned(100,16));
--        when 270 => period <=std_logic_vector(to_unsigned(99 ,16));
--        when 271 => period <=std_logic_vector(to_unsigned(99 ,16));
--        when 272 => period <=std_logic_vector(to_unsigned(99 ,16));
--        when 273 => period <=std_logic_vector(to_unsigned(98 ,16));
--        when 274 => period <=std_logic_vector(to_unsigned(98 ,16));
--        when 275 => period <=std_logic_vector(to_unsigned(98 ,16));
--        when 276 => period <=std_logic_vector(to_unsigned(97 ,16));
--        when 277 => period <=std_logic_vector(to_unsigned(97 ,16));
--        when 278 => period <=std_logic_vector(to_unsigned(97 ,16));
--        when 279 => period <=std_logic_vector(to_unsigned(96 ,16));
--        when 280 => period <=std_logic_vector(to_unsigned(96 ,16));
--        when 281 => period <=std_logic_vector(to_unsigned(96 ,16));
--        when 282 => period <=std_logic_vector(to_unsigned(95 ,16));
--        when 283 => period <=std_logic_vector(to_unsigned(95 ,16));
--        when 284 => period <=std_logic_vector(to_unsigned(94 ,16));
--        when 285 => period <=std_logic_vector(to_unsigned(94 ,16));
--        when 286 => period <=std_logic_vector(to_unsigned(94 ,16));
--        when 287 => period <=std_logic_vector(to_unsigned(94 ,16));
--        when 288 => period <=std_logic_vector(to_unsigned(93 ,16));
--        when 289 => period <=std_logic_vector(to_unsigned(93 ,16));
--        when 290 => period <=std_logic_vector(to_unsigned(93 ,16));
--        when 291 => period <=std_logic_vector(to_unsigned(92 ,16));
--        when 292 => period <=std_logic_vector(to_unsigned(92 ,16));
--        when 293 => period <=std_logic_vector(to_unsigned(92 ,16));
--        when 294 => period <=std_logic_vector(to_unsigned(91 ,16));
--        when 295 => period <=std_logic_vector(to_unsigned(91 ,16));
--        when 296 => period <=std_logic_vector(to_unsigned(91 ,16));
--        when 297 => period <=std_logic_vector(to_unsigned(90 ,16));
--        when 298 => period <=std_logic_vector(to_unsigned(90 ,16));
--        when 299 => period <=std_logic_vector(to_unsigned(90 ,16));
--        when 300 => period <=std_logic_vector(to_unsigned(89 ,16));
--        when 301 => period <=std_logic_vector(to_unsigned(89 ,16));
--        when 302 => period <=std_logic_vector(to_unsigned(89 ,16));
--        when 303 => period <=std_logic_vector(to_unsigned(89 ,16));
--        when 304 => period <=std_logic_vector(to_unsigned(88 ,16));
--        when 305 => period <=std_logic_vector(to_unsigned(88 ,16));
--        when 306 => period <=std_logic_vector(to_unsigned(88 ,16));
--        when 307 => period <=std_logic_vector(to_unsigned(88 ,16));
--        when 308 => period <=std_logic_vector(to_unsigned(87 ,16));
--        when 309 => period <=std_logic_vector(to_unsigned(87 ,16));
--        when 310 => period <=std_logic_vector(to_unsigned(87 ,16));
--        when 311 => period <=std_logic_vector(to_unsigned(86 ,16));
--        when 312 => period <=std_logic_vector(to_unsigned(86 ,16));
--        when 313 => period <=std_logic_vector(to_unsigned(86 ,16));
--        when 314 => period <=std_logic_vector(to_unsigned(85 ,16));
--        when 315 => period <=std_logic_vector(to_unsigned(85 ,16));
--        when 316 => period <=std_logic_vector(to_unsigned(85 ,16));
--        when 317 => period <=std_logic_vector(to_unsigned(85 ,16));
--        when 318 => period <=std_logic_vector(to_unsigned(84 ,16));
--        when 319 => period <=std_logic_vector(to_unsigned(84 ,16));
--        when 320 => period <=std_logic_vector(to_unsigned(84 ,16));
--        when 321 => period <=std_logic_vector(to_unsigned(84 ,16));
--        when 322 => period <=std_logic_vector(to_unsigned(83 ,16));
--        when 323 => period <=std_logic_vector(to_unsigned(83 ,16));
--        when 324 => period <=std_logic_vector(to_unsigned(83 ,16));
--        when 325 => period <=std_logic_vector(to_unsigned(83 ,16));
--        when 326 => period <=std_logic_vector(to_unsigned(83 ,16));
--        when 327 => period <=std_logic_vector(to_unsigned(82 ,16));
--        when 328 => period <=std_logic_vector(to_unsigned(82 ,16));
--        when 329 => period <=std_logic_vector(to_unsigned(82 ,16));
--        when 330 => period <=std_logic_vector(to_unsigned(81 ,16));
--        when 331 => period <=std_logic_vector(to_unsigned(81 ,16));
--        when 332 => period <=std_logic_vector(to_unsigned(81 ,16));
--        when 333 => period <=std_logic_vector(to_unsigned(81 ,16));
--        when 334 => period <=std_logic_vector(to_unsigned(80 ,16));
--        when 335 => period <=std_logic_vector(to_unsigned(80 ,16));
--        when 336 => period <=std_logic_vector(to_unsigned(80 ,16));
--        when 337 => period <=std_logic_vector(to_unsigned(80 ,16));
--        when 338 => period <=std_logic_vector(to_unsigned(80 ,16));
--        when 339 => period <=std_logic_vector(to_unsigned(79 ,16));
--        when 340 => period <=std_logic_vector(to_unsigned(79 ,16));
--        when 341 => period <=std_logic_vector(to_unsigned(79 ,16));
--        when 342 => period <=std_logic_vector(to_unsigned(79 ,16));
--        when 343 => period <=std_logic_vector(to_unsigned(78 ,16));
--        when 344 => period <=std_logic_vector(to_unsigned(78 ,16));
--        when 345 => period <=std_logic_vector(to_unsigned(78 ,16));
--        when 346 => period <=std_logic_vector(to_unsigned(78 ,16));
--        when 347 => period <=std_logic_vector(to_unsigned(77 ,16));
--        when 348 => period <=std_logic_vector(to_unsigned(77 ,16));
--        when 349 => period <=std_logic_vector(to_unsigned(77 ,16));
--        when 350 => period <=std_logic_vector(to_unsigned(77 ,16));
--        when 351 => period <=std_logic_vector(to_unsigned(77 ,16));
--        when 352 => period <=std_logic_vector(to_unsigned(76 ,16));
--        when 353 => period <=std_logic_vector(to_unsigned(76 ,16));
--        when 354 => period <=std_logic_vector(to_unsigned(76 ,16));
--        when 355 => period <=std_logic_vector(to_unsigned(76 ,16));
--        when 356 => period <=std_logic_vector(to_unsigned(76 ,16));
--        when 357 => period <=std_logic_vector(to_unsigned(75 ,16));
--        when 358 => period <=std_logic_vector(to_unsigned(75 ,16));
--        when 359 => period <=std_logic_vector(to_unsigned(75 ,16));
--        when 360 => period <=std_logic_vector(to_unsigned(75 ,16));
--        when 361 => period <=std_logic_vector(to_unsigned(74 ,16));
--        when 362 => period <=std_logic_vector(to_unsigned(74 ,16));
--        when 363 => period <=std_logic_vector(to_unsigned(74 ,16));
--        when 364 => period <=std_logic_vector(to_unsigned(74 ,16));
--        when 365 => period <=std_logic_vector(to_unsigned(74 ,16));
--        when 366 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 367 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 368 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 369 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 370 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 371 => period <=std_logic_vector(to_unsigned(73 ,16));
--        when 372 => period <=std_logic_vector(to_unsigned(72 ,16));
--        when 373 => period <=std_logic_vector(to_unsigned(72 ,16));
--        when 374 => period <=std_logic_vector(to_unsigned(72 ,16));
--        when 375 => period <=std_logic_vector(to_unsigned(72 ,16));
--        when 376 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 377 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 378 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 379 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 380 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 381 => period <=std_logic_vector(to_unsigned(71 ,16));
--        when 382 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 383 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 384 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 385 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 386 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 387 => period <=std_logic_vector(to_unsigned(70 ,16));
--        when 388 => period <=std_logic_vector(to_unsigned(69 ,16));
--        when 389 => period <=std_logic_vector(to_unsigned(69 ,16));
--        when 390 => period <=std_logic_vector(to_unsigned(69 ,16));
--        when 391 => period <=std_logic_vector(to_unsigned(69 ,16));
--        when 392 => period <=std_logic_vector(to_unsigned(69 ,16));
--        when 393 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 394 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 395 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 396 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 397 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 398 => period <=std_logic_vector(to_unsigned(68 ,16));
--        when 399 => period <=std_logic_vector(to_unsigned(67 ,16));
--        when 400 => period <=std_logic_vector(to_unsigned(67 ,16));
--        when 401 => period <=std_logic_vector(to_unsigned(67 ,16));
                         

--        when others => period <= std_logic_vector(to_unsigned(400 ,16));
--        end case;
    end if;
end process;
end Behavioral;
