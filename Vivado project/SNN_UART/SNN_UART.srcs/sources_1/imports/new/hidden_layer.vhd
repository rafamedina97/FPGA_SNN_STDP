LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity grouping all the modules that compose a hidden layer
------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity hidden_layer is
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
end hidden_layer;

architecture behaviour of hidden_layer is

    component layer_control is
        generic(
            MAX_NEURONS :           integer;    -- Number of neurons of the largest layer
            PREV_LAYER_NEURONS :    integer     -- Number of neurons in the layer
        );
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            -- Shift registers control
            in_ilr_shift_en :   in std_logic;   -- Enables shifting in the inter-layer circular registers
            out_ilr_shift_en :  out std_logic;
            in_ilr_store_en :   in std_logic;   -- Enables the storing of data in the inter-layer circular registers
            out_ilr_store_en :  out std_logic;
            in_lir_shift_en :   in std_logic;   -- Enables shifting in the lateral inhibition regsiters
            out_lir_shift_en :  out std_logic;
            in_lir_store_en :   in std_logic;   -- Enables the storing of data in the lateral inhibition registers
            out_lir_store_en :  out std_logic;
            -- Layer control communication
            in_send_li_flag :   in std_logic;   -- Prompts the layer control to send the correspondant lateral inhibition flag
            in_send_V_srst :    in std_logic;   -- Prompts the layer control to reset the tension register
            li_input :          in std_logic;   -- Lateral inhibition input from the shift register
            li_flag :           out std_logic;  -- Lateral inhibition output flag for the layer
            -- STDP control
            in_we_ram :         in std_logic_vector(0 to 0);                                            -- Enables writing in the synaptic weights memories
            out_we_ram :        out std_logic_vector(0 to 0);
            in_o_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Reading address of the synaptic weights memories
            out_o_addr :        out std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);
            in_w_addr :         in std_logic_vector(log2c(MAX_NEURONS)-1 downto 0); -- Writing address of the synaptic weights memories
            out_w_addr :        out std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);
            in_valid_spike :    in std_logic;                                                           -- Enables count for the last spikes counter
            out_valid_spike :   out std_logic;
            in_tau_cnt_srst :   in std_logic;                                                           -- Resets the last spikes counters
            out_tau_cnt_srst :  out std_logic;
            -- LIF control
            in_mux_sel :        in std_logic_vector(1 downto 0);                -- LIF multiplexor select signal
            out_mux_sel :       out std_logic_vector(1 downto 0);
            in_shift :          in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Shift in the barrel shifter in order to perform the multiplication
            out_shift :         out std_logic_vector(WEIGHT_bits-1 downto 0);
            in_V_reg_en :       in std_logic;                                   -- LIF tension register enable
            out_V_reg_en :      out std_logic;
            in_V_srst_en :      in std_logic;                                   -- LIF tension register synchronous reset enable
            out_V_srst_en :     out std_logic;
            in_acc_reg_en :     in std_logic;                                   -- LIF accumulator register enable
            out_acc_reg_en :    out std_logic;
            in_acc_srst :       in std_logic;                                   -- LIF accumulator register synchronous reset
            out_acc_srst :      out std_logic;
            in_spike_reg_en :   in std_logic;                                   -- LIF spike register enable
            out_spike_reg_en :  out std_logic
        );
    end component;
    
    component one_neuron is
        generic(
            PREV_LAYER_NEURONS :    integer;
            LAYER :                 integer;
            NEURON :                integer
        );
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            -- Control inputs
            mux_sel :           in std_logic_vector(1 downto 0);                -- Selection of the multiplexor           
            shift :             in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Bits the barrel shifter must shift
            V_reg_en :          in std_logic;                                   -- Tension register enable
            V_srst_en :         in std_logic;                                   -- Tension register synchronous reset enable
            acc_reg_en :        in std_logic;                                   -- Accumulator register enable
            acc_srst :          in std_logic;                                   -- Accumulator register synchronous reset
            spike_reg_en :      in std_logic;                                   -- Spike register enable
            tau_cnt_srst :      in std_logic;                                   -- Synchronous reset of the last spikes register
            valid_spike :       in std_logic;                                   -- Control signal for registering the last spike
            we_ram :            in std_logic_vector(0 to 0);                                                    -- Enables writing in the synaptic weights memories
            o_addr :            in std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);  -- Reading address of the synaptic weights memories
            w_addr :            in std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);  -- Writing address of the synaptic weights memories
            -- General in/out
            spike_prev :        in std_logic;                                   -- Spike of the correspondant neuron in the previous layer
            flag_li :           in std_logic;                                   -- Signal for lateral inhibition from control
            tau_spikes_prev :   in std_logic_vector(T_BACK_bits-1 downto 0);    -- Simulation steps since the last spike of thecorrespondant neuron in the previous layer
            spike_out :         out std_logic;                                  -- Neuron spike
            tau_spikes_out :    out std_logic_vector(T_BACK_bits-1 downto 0)    -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;
    
    component inter_layer_reg is
        generic(
            NEURONS : integer
        );
        port(
            reset :         in std_logic;                               
            clk :           in std_logic; 
            last_sp_in :    in last_spikes_reg(NEURONS-1 downto 0);     -- Input of the time of the last spike for each neuron
            spikes_in :     in std_logic_vector(NEURONS-1 downto 0);    -- Input of the spike for each neuron
            valid_in :      in std_logic;                               -- Allows for storing the data inputs
            shift_en :      in std_logic;                               -- Enables the shifting of registers
            last_sp_out :   out last_spikes_reg(NEURONS-1 downto 0);    -- Output for each register of the time of last spikes
            spikes_out :    out std_logic_vector(NEURONS-1 downto 0)    -- Output for each register of the spikes
        );
    end component;
    
    component LI_register is
        generic(
            NEURONS : integer
        );
        port(
            reset :     in std_logic;
            clk :       in std_logic;
            d_in :      in std_logic_vector(NEURONS-1 downto 0);    -- Lateral inhibition flag from each neuron
            valid_in :  in std_logic;                               -- Allows for storing the flags
            shift_en :  in std_logic;                               -- Enables the register shifting
            d_out :     out std_logic                               -- Serial output of the lateral inhibition flags
        );
    end component;
    
    constant N_ILR : integer := div_ceil(NEURONS, PREV_LAYER_NEURONS);  -- How many inter_layer_register are needed
    constant ILR_offset : integer := NEURONS rem PREV_LAYER_NEURONS;
    
    signal ilr_store_en, ilr_shift_en, lir_store_en, lir_shift_en : std_logic;
    signal li_input, li_flag : std_logic;
    signal we_ram : std_logic_vector(0 downto 0);
    signal o_addr, w_addr : std_logic_vector(log2c(PREV_LAYER_NEURONS)-1 downto 0);
    signal valid_spike, tau_cnt_srst : std_logic;
    signal mux_sel : std_logic_vector(1 downto 0);
    signal shift : std_logic_vector(WEIGHT_bits-1 downto 0);
    signal V_reg_en, V_srst_en, acc_reg_en, acc_srst, spike_reg_en : std_logic;
    signal spike_prev, spike_intern : std_logic_vector(NEURONS-1 downto 0);
    signal tau_spikes_prev : last_spikes_reg(NEURONS-1 downto 0);
    signal open_spikes : std_logic_vector(PREV_LAYER_NEURONS-1 downto ILR_offset) := (others => '0');
    signal open_tau : last_spikes_reg(PREV_LAYER_NEURONS-1 downto ILR_offset) := (others => (others => '0'));

begin

    U_HID_CONTROL : layer_control
        generic map(
            MAX_NEURONS =>          MAX_NEURONS,
            PREV_LAYER_NEURONS =>   PREV_LAYER_NEURONS
        )
        port map(
            reset =>            reset,
            clk =>              clk,
            -- Shift registers control
            in_ilr_shift_en =>  in_ilr_shift_en,
            out_ilr_shift_en => ilr_shift_en,
            in_ilr_store_en =>  in_ilr_store_en,
            out_ilr_store_en => ilr_store_en,
            in_lir_shift_en =>  in_lir_shift_en,
            out_lir_shift_en => lir_shift_en,
            in_lir_store_en =>  in_lir_store_en,
            out_lir_store_en => lir_store_en,
            -- Layer control communication
            in_send_li_flag =>  in_send_li_flag,
            in_send_V_srst =>   in_send_V_srst,
            li_input =>         li_input,
            li_flag =>          li_flag,
            -- STDP control
            in_we_ram =>        in_we_ram,
            out_we_ram =>       we_ram,
            in_o_addr =>        in_o_addr,
            out_o_addr =>       o_addr,
            in_w_addr =>        in_w_addr,
            out_w_addr =>       w_addr,
            in_valid_spike =>   in_valid_spike,
            out_valid_spike =>  valid_spike,
            in_tau_cnt_srst =>  in_tau_cnt_srst,
            out_tau_cnt_srst => tau_cnt_srst,
            -- LIF control
            in_mux_sel =>       in_mux_sel,
            out_mux_sel =>      mux_sel,
            in_shift =>         in_shift,
            out_shift =>        shift,
            in_V_reg_en =>      in_V_reg_en,
            out_V_reg_en =>     V_reg_en,
            in_V_srst_en =>     in_V_srst_en,
            out_V_srst_en =>    V_srst_en,
            in_acc_reg_en =>    in_acc_reg_en,
            out_acc_reg_en =>   acc_reg_en,
            in_acc_srst =>      in_acc_srst,
            out_acc_srst =>     acc_srst,
            in_spike_reg_en =>  in_spike_reg_en,
            out_spike_reg_en => spike_reg_en
        );
        
    NEURON_GEN :
    for n in 0 to NEURONS-1 generate
        U_NEURON : one_neuron
            generic map(
                PREV_LAYER_NEURONS =>   PREV_LAYER_NEURONS,
                LAYER =>                LAYER,
                NEURON =>               n
            )
            port map(
                reset =>            reset,
                clk =>              clk,
                -- Control inputs
                mux_sel =>          mux_sel,         
                shift =>            shift,
                V_reg_en =>         V_reg_en,
                V_srst_en =>        V_srst_en,
                acc_reg_en =>       acc_reg_en,
                acc_srst =>         acc_srst,
                spike_reg_en =>     spike_reg_en,
                tau_cnt_srst =>     tau_cnt_srst,
                valid_spike =>      valid_spike,
                we_ram =>           we_ram,
                o_addr =>           o_addr,
                w_addr =>           w_addr,
                -- General in/out
                spike_prev =>       spike_prev(n),
                flag_li =>          li_flag,
                tau_spikes_prev =>  tau_spikes_prev(n),
                spike_out =>        spike_intern(n),
                tau_spikes_out =>   tau_spikes_out(n)
            );
    end generate;
    
    ILR_GEN :
    for i in 0 to N_ILR-1 generate
        FULL_ILR : if i < N_ILR-1 generate
            U_ILR_FULL : inter_layer_reg
                generic map(
                    NEURONS =>  PREV_LAYER_NEURONS  
                )
                port map(
                    reset =>        reset,
                    clk =>          clk,
                    last_sp_in =>   tau_spikes_pre_lay,
                    spikes_in =>    spike_pre_lay,
                    valid_in =>     ilr_store_en,
                    shift_en =>     ilr_shift_en,
                    last_sp_out =>  tau_spikes_prev((i+1)*PREV_LAYER_NEURONS-1 downto i*PREV_LAYER_NEURONS),
                    spikes_out =>   spike_prev((i+1)*PREV_LAYER_NEURONS-1 downto i*PREV_LAYER_NEURONS)
                );
        end generate;
        LAST_ILR : if i = N_ILR-1 generate
            FIT_ILR : if ILR_offset = 0 generate  -- If the last ILR is has all the outputs connected to neurons
                U_ILR_LAST_FIT : inter_layer_reg
                    generic map(
                        NEURONS =>  PREV_LAYER_NEURONS  
                    )
                    port map(
                        reset =>        reset,
                        clk =>          clk,
                        last_sp_in =>   tau_spikes_pre_lay,
                        spikes_in =>    spike_pre_lay,
                        valid_in =>     ilr_store_en,
                        shift_en =>     ilr_shift_en,
                        last_sp_out =>  tau_spikes_prev((i+1)*PREV_LAYER_NEURONS-1 downto i*PREV_LAYER_NEURONS),
                        spikes_out =>   spike_prev((i+1)*PREV_LAYER_NEURONS-1 downto i*PREV_LAYER_NEURONS)
                    );
            end generate;
            UNFIT_ILR : if ILR_offset > 0 generate  -- If the last ILR is has not all the outputs connected to neurons
                U_ILR_LAST_UNFIT : inter_layer_reg
                    generic map(
                        NEURONS =>  PREV_LAYER_NEURONS  
                    )
                    port map(
                        reset =>        reset,
                        clk =>          clk,
                        last_sp_in =>   tau_spikes_pre_lay,
                        spikes_in =>    spike_pre_lay,
                        valid_in =>     ilr_store_en,
                        shift_en =>     ilr_shift_en,
                        last_sp_out(PREV_LAYER_NEURONS-1 downto ILR_offset) =>  open_tau,
                        last_sp_out(ILR_offset-1 downto 0) =>                   tau_spikes_prev(i*PREV_LAYER_NEURONS+ILR_offset-1 downto i*PREV_LAYER_NEURONS),
                        spikes_out(PREV_LAYER_NEURONS-1 downto ILR_offset) =>   open_spikes,
                        spikes_out(ILR_offset-1 downto 0) =>                    spike_prev(i*PREV_LAYER_NEURONS+ILR_offset-1 downto i*PREV_LAYER_NEURONS)
                    );
            end generate;
        end generate;
    end generate;
    
    U_LIR : LI_register
        generic map(
            NEURONS =>  NEURONS
        )
        port map(
            reset =>    reset,
            clk =>      clk,
            d_in =>     spike_intern,
            valid_in => lir_store_en,
            shift_en => lir_shift_en,
            d_out =>    li_input
        );
    
    spike_out <= spike_intern;

end behaviour;