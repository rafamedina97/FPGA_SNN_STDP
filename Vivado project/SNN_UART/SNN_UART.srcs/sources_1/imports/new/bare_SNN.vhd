LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.rl_pkg.all;
use work.log2_pkg.all;
use work.int_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity encompassign the whole SNN, without the receptive layer: input, output and hidden layers, plus the network control
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity bare_SNN is
    generic(
        LAYER_NUM :     integer := 3;
        LAYER_SIZES :   int_vector(0 to LAYER_NUM-1) := (10, 8, 4)
    );
    port(
        reset :			in std_logic;
		clk :		    in std_logic;
		-- General control
		start_step :    in std_logic;                               -- Signals the start of the computation of a simulation step
        step_num :      in unsigned(STEPS_bits-1 downto 0);         -- Number of the simulation step to compute
        step_finish :   out std_logic;                              -- Signals the end of the step computation
        -- Period control
        period_store :  in std_logic;                                   -- Enables the storing of the correspondant period
        period :        in period_vector(LAYER_SIZES(0)-1 downto 0);    -- Period computed
        -- Spikes output
        spikes_out :    out std_logic_vector(LAYER_SIZES(LAYER_NUM-1)-1 downto 0) -- Spike outputs of the output layer
    );
end bare_SNN;

architecture behaviour of bare_SNN is

    -- Obtaining the size of the largest layer
    constant MAX_NEURONS : integer := max_int(LAYER_SIZES);
    
    -- Declaring types for the spikes and last spikes interconnections between layers
    subtype spike_bus is std_logic_vector(MAX_NEURONS-1 downto 0);
    type spike_bus_array is array(integer range <>) of spike_bus;
    subtype last_spikes_bus is last_spikes_reg(MAX_NEURONS-1 downto 0);
    type last_spikes_bus_array is array(integer range <>) of last_spikes_bus;
    
    component network_control is
        generic(
            MAX_NEURONS :   integer     -- Number of neurons of the larger layer
        );
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            -- Communication interface
            start_step :        in std_logic;                       -- Signals the start of the computation of a simulation step
            step_num :          in unsigned(STEPS_bits-1 downto 0); -- Number of the simulation step to compute
            step_finish :       out std_logic;                      -- Signals the end of the computation
            -- Input neurons control
            input_cnt_en :      out std_logic;  -- Enables counting for the input layer neurons
            input_cnt_srst :    out std_logic;  -- Resets the input layer neurons counters      
            -- Shift registers control
            ilr_shift_en :      out std_logic;  -- Enables shifting in the inter-layer circular registers
            ilr_store_en :      out std_logic;  -- Enables the storing of data in the inter-layer circular registers
            lir_shift_en :      out std_logic;  -- Enables shifting in the lateral inhibition regsiters
            lir_store_en :      out std_logic;  -- Enables the storing of data in the lateral inhibition registers
            -- Layer control communication
            send_li_flag :      out std_logic;  -- Prompts the layer control to send the correspondant lateral inhibition flag
            send_V_srst :       out std_logic;  -- Prompts the layer control to reset the tension register
            -- STDP control
            we_ram :            out std_logic_vector(0 to 0);                                               -- Enables writing in the synaptic weights memories
            o_addr :            out std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);    -- Reading address of the synaptic weights memories
            w_addr :            out std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);    -- Writing address of the synaptic weights memories
            valid_spike :       out std_logic;                                                              -- Enables count for the last spikes counter
            tau_cnt_srst :      out std_logic;                                                              -- Resets the last spikes counters
            -- LIF control
            mux_sel :           out std_logic_vector(1 downto 0);               -- LIF multiplexor select signal
            shift :             out std_logic_vector(WEIGHT_bits-1 downto 0);   -- Shift in the barrel shifter in order to perform the multiplication
            V_reg_en :          out std_logic;                                  -- LIF tension register enable
            V_srst_en :         out std_logic;                                  -- LIF tension register synchronous reset enable
            acc_reg_en :        out std_logic;                                  -- LIF accumulator register enable
            acc_srst :          out std_logic;                                  -- LIF accumulator register synchronous reset
            spike_reg_en :      out std_logic                                   -- LIF spike register enable
        );
    end component;
    
    component input_layer is
        generic(
            NEURONS :   integer
        );
        port(
            reset :                 in std_logic;
            clk :                   in std_logic;
            -- Control inputs
            in_input_cnt_en :       in std_logic;                               -- Enables counting for the input layer neurons
            in_input_cnt_srst :     in std_logic;                               -- Resets the input layer neurons counters
            in_valid_spike :        in std_logic;                               -- Enables count for the last spikes counter
            in_tau_cnt_srst :       in std_logic;                               -- Resets the last spikes counters
            in_spike_reg_en :       in std_logic;                               -- LIF spike register enable
            in_period_store :       in std_logic;                               -- Enables the storing of the correspondant period
            -- General in/out
            period :                in period_vector(NEURONS-1 downto 0);       -- Period computed
            spike_out :             out std_logic_vector(NEURONS-1 downto 0);   -- Spike output
            tau_spikes_out :        out last_spikes_reg(NEURONS-1 downto 0)     -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;
    
    component hidden_layer is
        generic(
            LAYER :                 integer;
            MAX_NEURONS :           integer;
            PREV_LAYER_NEURONS :    integer;
            NEURONS :               integer
        );
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            -- Control inputs ---------------------------------------------------------------------
            -- Shift registers control
            in_ilr_shift_en :   in std_logic;   -- Enables shifting in the inter-layer circular registers
            in_ilr_store_en :   in std_logic;   -- Enables the storing of data in the inter-layer circular registers
            in_lir_shift_en :   in std_logic;   -- Enables shifting in the lateral inhibition regsiters
            in_lir_store_en :   in std_logic;   -- Enables the storing of data in the lateral inhibition registers
            -- Layer control communication
            in_send_li_flag :   in std_logic;   -- Prompts the layer control to send the correspondant lateral inhibition flag
            in_send_V_srst :    in std_logic;   -- Prompts the layer control to reset the tension register
            -- STDP control
            in_we_ram :         in std_logic_vector(0 to 0);                        -- Enables writing in the synaptic weights memories
            in_o_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Reading address of the synaptic weights memories
            in_w_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Writing address of the synaptic weights memories
            in_valid_spike :    in std_logic;                                       -- Enables count for the last spikes counter
            in_tau_cnt_srst :   in std_logic;                                       -- Resets the last spikes counters
            -- LIF control
            in_mux_sel :        in std_logic_vector(1 downto 0);                -- LIF multiplexor select signal
            in_shift :          in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Shift in the barrel shifter in order to perform the multiplication
            in_V_reg_en :       in std_logic;                                   -- LIF tension register enable
            in_V_srst_en :      in std_logic;                                   -- LIF tension register synchronous reset enable
            in_acc_reg_en :     in std_logic;                                   -- LIF accumulator register enable
            in_acc_srst :       in std_logic;                                   -- LIF accumulator register synchronous reset
            in_spike_reg_en :   in std_logic;                                   -- LIF spike register enable
            -- General in/out ---------------------------------------------------------------------
            spike_pre_lay :         in std_logic_vector(PREV_LAYER_NEURONS-1 downto 0); -- Spike output from the previous layer
            tau_spikes_pre_lay :    in last_spikes_reg(PREV_LAYER_NEURONS-1 downto 0);  -- Simulation steps since the last spike (if > T_BACK outputs 0) from the previous layer
            spike_out :             out std_logic_vector(NEURONS-1 downto 0);           -- Spike output
            tau_spikes_out :        out last_spikes_reg(NEURONS-1 downto 0)             -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;
    
    component output_layer is
        generic(
            LAYER :                 integer;
            MAX_NEURONS :           integer;
            PREV_LAYER_NEURONS :    integer;
            NEURONS :               integer
        );
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            -- Control inputs ---------------------------------------------------------------------
            -- Shift registers control
            in_ilr_shift_en :   in std_logic;   -- Enables shifting in the inter-layer circular registers
            in_ilr_store_en :   in std_logic;   -- Enables the storing of data in the inter-layer circular registers
            in_lir_shift_en :   in std_logic;   -- Enables shifting in the lateral inhibition regsiters
            in_lir_store_en :   in std_logic;   -- Enables the storing of data in the lateral inhibition registers
            -- Layer control communication
            in_send_li_flag :   in std_logic;   -- Prompts the layer control to send the correspondant lateral inhibition flag
            in_send_V_srst :    in std_logic;   -- Prompts the layer control to reset the tension register
            -- STDP control
            in_we_ram :         in std_logic_vector(0 to 0);                        -- Enables writing in the synaptic weights memories
            in_o_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Reading address of the synaptic weights memories
            in_w_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Writing address of the synaptic weights memories
            in_valid_spike :    in std_logic;                                       -- Enables count for the last spikes counter
            in_tau_cnt_srst :   in std_logic;                                       -- Resets the last spikes counters
            -- LIF control
            in_mux_sel :        in std_logic_vector(1 downto 0);                -- LIF multiplexor select signal
            in_shift :          in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Shift in the barrel shifter in order to perform the multiplication
            in_V_reg_en :       in std_logic;                                   -- LIF tension register enable
            in_V_srst_en :      in std_logic;                                   -- LIF tension register synchronous reset enable
            in_acc_reg_en :     in std_logic;                                   -- LIF accumulator register enable
            in_acc_srst :       in std_logic;                                   -- LIF accumulator register synchronous reset
            in_spike_reg_en :   in std_logic;                                   -- LIF spike register enable
            -- General in/out ---------------------------------------------------------------------
            spike_pre_lay :         in std_logic_vector(PREV_LAYER_NEURONS-1 downto 0); -- Spike output from the previous layer
            tau_spikes_pre_lay :    in last_spikes_reg(PREV_LAYER_NEURONS-1 downto 0);  -- Simulation steps since the last spike (if > T_BACK outputs 0) from the previous layer
            spike_out :             out std_logic_vector(NEURONS-1 downto 0)            -- Spike output
        );
    end component;
    
    signal cnt_en, cnt_srst : std_logic;
    signal ilr_store_en, ilr_shift_en, lir_store_en, lir_shift_en : std_logic;
    signal send_li_flag, send_V_srst : std_logic;
    signal we_ram : std_logic_vector(0 downto 0);
    signal o_addr, w_addr : std_logic_vector(log2c(MAX_NEURONS)-1 downto 0);
    signal valid_spike, tau_cnt_srst : std_logic;
    signal mux_sel : std_logic_vector(1 downto 0);
    signal shift : std_logic_vector(WEIGHT_bits-1 downto 0);
    signal V_reg_en, V_srst_en, acc_reg_en, acc_srst, spike_reg_en : std_logic;
    
    signal spike_comm : spike_bus_array(0 to LAYER_NUM-1);
    signal last_spikes_comm : last_spikes_bus_array(0 to LAYER_NUM-2);
       
begin
    
    U_CONTROL : network_control
        generic map(
            MAX_NEURONS =>  MAX_NEURONS
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            -- Communication interface
            start_step =>       start_step,
            step_num =>         step_num,
            step_finish =>      step_finish,
            -- Input neurons control
            input_cnt_en =>     cnt_en,
            input_cnt_srst =>   cnt_srst,
            -- Shift registers control
            ilr_shift_en =>     ilr_shift_en,
            ilr_store_en =>     ilr_store_en,
            lir_shift_en =>     lir_shift_en,
            lir_store_en =>     lir_store_en,
            -- Layer control communication
            send_li_flag =>     send_li_flag,
            send_V_srst =>      send_V_srst,
            -- STDP control
            we_ram =>           we_ram,
            o_addr =>           o_addr,
            w_addr =>           w_addr,
            valid_spike =>      valid_spike,
            tau_cnt_srst =>     tau_cnt_srst,
            -- LIF control
            mux_sel =>          mux_sel,
            shift =>            shift,
            V_reg_en =>         V_reg_en,
            V_srst_en =>        V_srst_en,
            acc_reg_en =>       acc_reg_en,
            acc_srst =>         acc_srst,
            spike_reg_en =>     spike_reg_en
        );
        
    U_INPUT_LAYER : input_layer
        generic map(
            NEURONS =>  LAYER_SIZES(0)
        )
        port map(
            reset =>                reset,
            clk =>                  clk,
            -- Control inputs
            in_input_cnt_en =>      cnt_en,
            in_input_cnt_srst =>    cnt_srst,
            in_valid_spike =>       valid_spike,
            in_tau_cnt_srst =>      tau_cnt_srst,
            in_spike_reg_en =>      spike_reg_en,
            in_period_store =>      period_store,
            -- General in/out
            period =>               period,
            spike_out =>            spike_comm(0)(LAYER_SIZES(0)-1 downto 0),
            tau_spikes_out =>       last_spikes_comm(0)(LAYER_SIZES(0)-1 downto 0)
        );
        
    HIDDEN_LAYER_GEN :
    for i in 1 to LAYER_NUM-2 generate
        U_HIDDEN_LAYER : hidden_layer
            generic map(
                LAYER =>                i,
                MAX_NEURONS =>          MAX_NEURONS,
                PREV_LAYER_NEURONS =>   LAYER_SIZES(i-1),
                NEURONS =>              LAYER_SIZES(i)
            )
            port map(
                reset =>                reset,
                clk =>                  clk,
                -- Control inputs ---------------------------------------------------------------------
                -- Shift registers control
                in_ilr_shift_en =>      ilr_shift_en,
                in_ilr_store_en =>      ilr_store_en,
                in_lir_shift_en =>      lir_shift_en,
                in_lir_store_en =>      lir_store_en,
                -- Layer control communication
                in_send_li_flag =>      send_li_flag,
                in_send_V_srst =>       send_V_srst,
                -- STDP control
                in_we_ram =>            we_ram,
                in_o_addr =>            o_addr,
                in_w_addr =>            w_addr,
                in_valid_spike =>       valid_spike,
                in_tau_cnt_srst =>      tau_cnt_srst,
                -- LIF control
                in_mux_sel =>           mux_sel,
                in_shift =>             shift,
                in_V_reg_en =>          V_reg_en,
                in_V_srst_en =>         V_srst_en,
                in_acc_reg_en =>        acc_reg_en,
                in_acc_srst =>          acc_srst,
                in_spike_reg_en =>      spike_reg_en,
                -- General in/out ---------------------------------------------------------------------
                spike_pre_lay =>        spike_comm(i-1)(LAYER_SIZES(i-1)-1 downto 0),
                tau_spikes_pre_lay =>   last_spikes_comm(i-1)(LAYER_SIZES(i-1)-1 downto 0),
                spike_out =>            spike_comm(i)(LAYER_SIZES(i)-1 downto 0),
                tau_spikes_out =>       last_spikes_comm(i)(LAYER_SIZES(i)-1 downto 0)
        );
    end generate;
    
    U_OUTPUT_LAYER : output_layer
        generic map(
            LAYER =>                LAYER_NUM-1,
            MAX_NEURONS =>          MAX_NEURONS,
            PREV_LAYER_NEURONS =>   LAYER_SIZES(LAYER_NUM-2),
            NEURONS =>              LAYER_SIZES(LAYER_NUM-1)
        )
        port map(
            reset =>                reset,
            clk =>                  clk,
            -- Control inputs ---------------------------------------------------------------------
            -- Shift registers control
            in_ilr_shift_en =>      ilr_shift_en,
            in_ilr_store_en =>      ilr_store_en,
            in_lir_shift_en =>      lir_shift_en,
            in_lir_store_en =>      lir_store_en,
            -- Layer control communication
            in_send_li_flag =>      send_li_flag,
            in_send_V_srst =>       send_V_srst,
            -- STDP control
            in_we_ram =>            we_ram,
            in_o_addr =>            o_addr,
            in_w_addr =>            w_addr,
            in_valid_spike =>       valid_spike,
            in_tau_cnt_srst =>      tau_cnt_srst,
            -- LIF control
            in_mux_sel =>           mux_sel,
            in_shift =>             shift,
            in_V_reg_en =>          V_reg_en,
            in_V_srst_en =>         V_srst_en,
            in_acc_reg_en =>        acc_reg_en,
            in_acc_srst =>          acc_srst,
            in_spike_reg_en =>      spike_reg_en,
            -- General in/out ---------------------------------------------------------------------
            spike_pre_lay =>        spike_comm(LAYER_NUM-2)(LAYER_SIZES(LAYER_NUM-2)-1 downto 0),
            tau_spikes_pre_lay =>   last_spikes_comm(LAYER_NUM-2)(LAYER_SIZES(LAYER_NUM-2)-1 downto 0),
            spike_out =>            spike_comm(LAYER_NUM-1)(LAYER_SIZES(LAYER_NUM-1)-1 downto 0)
        );
    
    spikes_out <= spike_comm(LAYER_NUM-1)(LAYER_SIZES(LAYER_NUM-1)-1 downto 0);
    
    SIGNAL_FILLER : for i in 0 to LAYER_NUM-1 generate
        spike_comm(i)(MAX_NEURONS-1 downto LAYER_SIZES(i)) <= (others => '0');
        TAU_FILLER : if i < LAYER_NUM-1 generate
            last_spikes_comm(i)(MAX_NEURONS-1 downto LAYER_SIZES(i)) <= (others => (others => '0'));
        end generate;
    end generate;
    
end behaviour;