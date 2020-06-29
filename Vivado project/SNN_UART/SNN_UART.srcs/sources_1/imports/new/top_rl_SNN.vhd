LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.math_real.all;

use work.param_pkg.all;
use work.rl_pkg.all;
use work.log2_pkg.all;
use work.int_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity wrapping the three main modules: the bare SNN, the receptive layer and the general control
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity top_rl_SNN is
    generic(
        LAYER_NUM :     integer := 3;
        LAYER_SIZES :   int_vector(0 to LAYER_NUM-1) := (784, 20, 10)
    );
    port(
        reset :			  in std_logic;
		clk :		      in std_logic;
		frame :           in std_logic_vector(31 downto 0);                                   -- 4 input pixels for the receptive layer
		arrived :         in std_logic;                                                       -- Signal that the 4 pixels are valid
		info_out :        out std_logic_vector(15 downto 0);                                  -- RL info output for the current convoluting image
		nxt_img_ready :   out std_logic;                                                      -- Signals the uP that it's ready for the next image
	    valid_winner :    out std_logic;                                                      -- Signals that the value of the winner neuron is valid
		winner_neuron :   out std_logic_vector(log2c(LAYER_SIZES(LAYER_NUM-1))-1 downto 0)    -- Tells which neuron won for the last image
    );
end top_rl_SNN;

architecture behaviour of top_rl_SNN is
    
    component Convolution
        generic(
            Nbits :     integer;
            entero :    integer;
            fraccion :  integer;
            per_bits :  integer
        );
        port(
            frame :             in std_logic_vector(31 downto 0);           -- 4 input pixels for the receptive layer
            clk :               in std_logic;                                   
            rst :               in std_logic;
            arrived :           in std_logic;                               -- Signal that the 4 pixels are valid
            valid_posttrain :   out std_logic;                              -- Signal that the period received form rl is valid
            period :            out std_logic_vector(per_bits-1 downto 0);  -- Period computed
            ready :             out std_logic;                              -- Signals the receptive layer is ready for a new image
            info_out :          out std_logic_vector(15 downto 0)           -- RL info output for the current convoluting image
        );
    end component;
    
    component bare_SNN is
        generic(
            LAYER_NUM :     integer := 3;
            LAYER_SIZES :   int_vector(0 to LAYER_NUM-1) := (10, 8, 4)
        );
        port(
            reset :			in std_logic;
            clk :		    in std_logic;
            -- General control
            start_step :    in std_logic;                                           -- Signals the start of the computation of a simulation step
            step_num :      in unsigned(STEPS_bits-1 downto 0);                     -- Number of the simulation step to compute
            step_finish :   out std_logic;                                          -- Signals the end of the step computation
            -- Period control
            period_store :  in std_logic;                                           -- Enables the storing of the correspondant period
            period :        in period_vector(LAYER_SIZES(0)-1 downto 0);            -- Period computed
            -- Spikes output
            spikes_out :    out std_logic_vector(LAYER_SIZES(LAYER_NUM-1)-1 downto 0) -- Spike outputs of the output layer
        );
    end component;
    
    component general_control
        generic(
            INPUT_LAYER_SIZE :  integer;
            OUTPUT_LAYER_SIZE : integer
        );
        port(
            reset :			  in std_logic;
            clk :		      in std_logic;
            -- Interface with the exterior
            nxt_img_ready :   out std_logic;                                              -- Signals the uP that the rl is ready for a new image
            valid_winner :    out std_logic;                                              -- Signals that the value of the winner neuron is valid
            winner_neuron :   out std_logic_vector(log2c(OUTPUT_LAYER_SIZE)-1 downto 0);  -- Sends to the uP which was the winner neuron in learning for an image
            -- Receptive layer
            valid_period :    in std_logic;                                               -- Signal that the period received form rl is valid
            period_in :       in period;                                                  -- Period received from the receptive layer        
            rl_ready :        in std_logic;                                               -- Signals that the rl is ready for a new image
            rl_info :         in std_logic_vector(15 downto 0);                           -- Info output from the receptive layer
            -- SNN
            start_step :      out std_logic;                                              -- Signals the start of the computation of a simulation step
            step_num :        out unsigned(STEPS_bits-1 downto 0);                        -- Number of the simulation step to compute 
            step_finish :     in std_logic;                                               -- Signals the end of the step computation
            spikes_out :      in std_logic_vector(OUTPUT_LAYER_SIZE-1 downto 0);          -- Spikes output for the step
            period_store :    out std_logic;                                              -- Enables the storing of the periods in the input layer
            period_out :      out period_vector(INPUT_LAYER_SIZE-1 downto 0)              -- Periods to store in the input layer
        );
    end component;
    
    constant INPUT_LAYER_SIZE : integer := LAYER_SIZES(0);
    constant OUTPUT_LAYER_SIZE : integer := LAYER_SIZES(LAYER_NUM-1);
    
    signal valid_posttrain, rl_ready, start_step, step_finish, period_store : std_logic;
    signal period_intern : std_logic_vector(MAX_PER_bits-1 downto 0);
    signal period_out : period_vector(INPUT_LAYER_SIZE-1 downto 0);
    signal info_intern : std_logic_vector(15 downto 0);
    signal spikes_out : std_logic_vector(OUTPUT_LAYER_SIZE-1 downto 0);
    signal step_num : unsigned(STEPS_bits-1 downto 0);
    
begin

    U_RL : Convolution
        generic map(
            Nbits =>    BITS_INTERP,
            entero =>   INT_INTERP,
            fraccion => FRAC_INTERP,
            per_bits => MAX_PER_bits
        )
        port map(
            frame =>            frame,
            clk =>              clk,
            rst =>              reset,
            arrived =>          arrived,
            valid_posttrain =>  valid_posttrain,
            period =>           period_intern,
            ready =>            rl_ready,
            info_out =>         info_intern
        );
        
    U_SNN : bare_SNN
        generic map(
            LAYER_NUM =>    LAYER_NUM,
            LAYER_SIZES =>  LAYER_SIZES
        )
        port map(
            reset =>        reset,
            clk =>          clk,
            -- General control
            start_step =>   start_step,
            step_num =>     step_num,
            step_finish =>  step_finish,
            -- Period control
            period_store => period_store,
            period =>       period_out,
            -- Spikes output
            spikes_out =>   spikes_out
        );
        
    U_CTRL : general_control
        generic map(
            INPUT_LAYER_SIZE =>     INPUT_LAYER_SIZE,
            OUTPUT_LAYER_SIZE =>    OUTPUT_LAYER_SIZE
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            -- Interface with the exterior
            nxt_img_ready =>    nxt_img_ready,
            valid_winner =>     valid_winner,
            winner_neuron =>    winner_neuron,
            -- Receptive layer
            valid_period =>     valid_posttrain,
            period_in =>        period(period_intern),
            rl_ready =>         rl_ready,
            rl_info =>          info_intern,
            -- SNN
            start_step =>       start_step,
            step_num =>         step_num,
            step_finish =>      step_finish,
            spikes_out =>       spikes_out,
            period_store =>     period_store,
            period_out =>       period_out
        );
        
        info_out <= info_intern;

end behaviour;