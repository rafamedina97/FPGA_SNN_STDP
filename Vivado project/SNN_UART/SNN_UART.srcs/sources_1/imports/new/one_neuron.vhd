LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

use work.param_pkg.all;
use work.log2_pkg.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity that corresponds to a neuron containing the synaptic weights file and LIF and STDP computing
------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
entity one_neuron is
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
end one_neuron;

architecture behaviour of one_neuron is

    component LIF is
        port(
            reset :         in std_logic;
            clk :           in std_logic;
            -- Control inputs
            mux_sel :       in std_logic_vector(1 downto 0);                -- Selection of the multiplexor           
            shift :         in std_logic_vector(WEIGHT_bits-1 downto 0);    -- Bits the barrel shifter must shift
            V_reg_en :      in std_logic;                                   -- Tension register enable
            V_srst_en :     in std_logic;                                   -- Tension register synchronous reset enable
            acc_reg_en :    in std_logic;                                   -- Accumulator register enable
            acc_srst :      in std_logic;                                   -- Accumulator register synchronous reset
            spike_reg_en :  in std_logic;                                   -- Spike register enable
            -- General in/out
            spike_prev :    in std_logic;                                   -- Spike of the correspondant neuron in the previous layer
            syn_weight :    in signed(WEIGHT_QUANT-1 downto 0);             -- Synaptic weight for the correspondant neuron in the previous layer
            flag_li :       in std_logic;                                   -- Signal for lateral inhibition from control
            spike_out :     out std_logic                                   -- Neuron spike
        );
    end component;
    
    component tau_counter is
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            srst :              in std_logic;
            spike :             in std_logic;                                   -- Spike of the local neuron
            valid_spike :       in std_logic;                                   -- Control signal for registering the spike
            tau_spikes_out :    out std_logic_vector(T_BACK_bits-1 downto 0)    -- Simulation steps since the last spike (if > T_BACK outputs 0)
        );
    end component;
    
    component adders_STDP is
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            exp_pos :           in signed(WEIGHT_QUANT-1 downto 0);             -- Value of the positive derivative for STDP
            exp_neg :           in signed(WEIGHT_QUANT-1 downto 0);             -- Value of the negative derivative for STDP
            syn_weight :        in std_logic_vector(WEIGHT_QUANT-1 downto 0);   -- Synaptic weight for the correspondant neuron in the previous layer
            next_syn_weight :   out std_logic_vector(WEIGHT_QUANT-1 downto 0)   -- Next synaptic weight for the correspondant neuron in the previous layer
        );
    end component;
    
    component LUTRAM_exp is
        port(
            reset :             in std_logic;
            clk :               in std_logic;
            spike :             in std_logic;                                   -- Local spike
            spike_prev :        in std_logic;                                   -- Spike of the correspondant neuron in the previous layer
            tau_spikes_local :  in std_logic_vector(T_BACK_bits-1 downto 0);    -- Simulation steps since the last spike of the local neuron
            tau_spikes_prev :   in std_logic_vector(T_BACK_bits-1 downto 0);    -- Simulation steps since the last spike of thecorrespondant neuron in the previous layer
            pos_der :           out signed(WEIGHT_QUANT-1 downto 0);            -- Value of the positive derivative for STDP
            neg_der :           out signed(WEIGHT_QUANT-1 downto 0)             -- Value of the negative derivative for STDP
        );
    end component;
    
    component prev_spikes_reg is
        port(
            reset :     in std_logic;
            clk :       in std_logic;
            d_in :      in std_logic;	-- Previous spike input
            d_out :     out std_logic	-- Previous spike output
        );
    end component;
    
--    component blk_mem_gen_0 is
--    component dummy_mem is
    component synaptic_mem is
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
    end component;
    
    signal syn_weight, next_syn_weight : std_logic_vector(WEIGHT_QUANT-1 downto 0);
    signal pos_der, neg_der : signed(WEIGHT_QUANT-1 downto 0);
    signal tau_spikes_intern : std_logic_vector(T_BACK_bits-1 downto 0);
    signal spike_intern, spike_prev_delayed : std_logic;
    
begin

    U_LIF: LIF
        port map(
            reset =>        reset,
            clk =>          clk,  
            -- Control inputs
            mux_sel =>      mux_sel,    
            shift =>        shift,
            V_reg_en =>     V_reg_en,
            V_srst_en =>    V_srst_en,
            acc_reg_en =>   acc_reg_en,
            acc_srst =>     acc_srst,
            spike_reg_en => spike_reg_en,
            -- General in/out
            spike_prev =>   spike_prev_delayed,
            syn_weight =>   signed(next_syn_weight),
            flag_li =>      flag_li,
            spike_out =>    spike_intern
        );

    U_TAU_CNT: tau_counter
        port map(
            reset =>            reset,
            clk =>              clk,
            srst =>             tau_cnt_srst,
            spike =>            spike_intern,
            valid_spike =>      valid_spike,
            tau_spikes_out =>   tau_spikes_intern
        );
        
    U_ADD : adders_STDP
        port map(
            reset =>            reset,
            clk =>              clk,
            exp_pos =>          pos_der,
            exp_neg =>          neg_der,
            syn_weight =>       syn_weight,
            next_syn_weight =>  next_syn_weight
        );
        
    U_LUT : LUTRAM_exp
        port map(
            reset =>            reset,
            clk =>              clk,
            spike =>            spike_intern,
            spike_prev =>       spike_prev,
            tau_spikes_local => tau_spikes_intern,
            tau_spikes_prev =>  tau_spikes_prev,
            pos_der =>          pos_der,
            neg_der =>          neg_der
        );
        
    U_REG : prev_spikes_reg
        port map(
            reset =>    reset,
            clk =>      clk,
            d_in =>     spike_prev,
            d_out =>    spike_prev_delayed
        );
        
--    U_RAM : blk_mem_gen_0 
--    U_RAM : dummy_mem
    U_RAM : synaptic_mem
        generic map(
            PREV_LAYER_NEURONS =>   PREV_LAYER_NEURONS,
            LAYER =>                LAYER,
            NEURON =>               NEURON
        )
        port map(
            clka =>     clk,
            wea =>      we_ram,
            addra =>    w_addr,
            dina =>     next_syn_weight,
            clkb =>     clk,
            addrb =>    o_addr,
            doutb =>    syn_weight
        );
        
    spike_out <= spike_intern;
    tau_spikes_out <= tau_spikes_intern;

end behaviour;