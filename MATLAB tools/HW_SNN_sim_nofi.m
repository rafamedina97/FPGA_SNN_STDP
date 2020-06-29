%   Script that simulates the hardware implemented SNN, with Iñaki's
%   receptive layer. It consists in a multi-layer SNN using LIF neurons and
%   pair-based STDP learning.

LS = [784 20 10];                       % Vector containing the layer sizes for the SNN (so far, 784 cannot be changed)

INT_QUANT = 8;                          % Integer bits for data in LIF and STDP
FRAC_QUANT = 16;                        % Fraction bits for data in LIF and STDP
WEIGHT_QUANT = INT_QUANT + FRAC_QUANT;  % Quantization bits for data in LIF and STDP
T_BACK = 20;                            % Number of past steps taken into account in STDP
BITS_T_BACK = ceil(log2(T_BACK));       % Bits needed to count to the maximum time window
INT_INTERP = 4;                         % Integer bits for data in the interpolation
FRAC_INTERP = 12;                       % Fraction bits for data in the interpolation
BITS_INTERP = INT_INTERP + FRAC_INTERP; % Quantization bits for data in the interpolation
BITS_FREQ = 16;                         % Quantization bits for frequency calculation
STEPS = 400;                            % Number of simulation steps
AUX_STEPS = 490;                        % Auxiliar number of simulation steps for frequency computation
MAX_PER = STEPS;                        % Maximum result for the input neuron counters
BITS_PER_LUT = ceil(log2(MAX_PER));     % Bits needed to represent all the resulting frequencies

INTERP_0 = 1;
INTERP_1 = 5/4;
MAX_INTERP = 4;
AUX_STEPS_INV = 2^-9 + 2^-14;
MIN_FREQ = 65;
MAX_FREQ = 401;

% Parameters of LIF and STDP
Vrest = 0;                                      % Resting potential for the LIF neurons
Vth = 1;                                        % Threshold potential for the LIF neurons
Vmin = -8;                                      % Minimum potential for the LIF neurons
Kt = double(fi(1/6,1,WEIGHT_QUANT,FRAC_QUANT)); % Parameter containg info about step size and time constant
A_pos = 1;                                      % STDP positive coefficient
A_neg = -1;                                     % STDP negative coefficient
sigma = 1e-1;                                   % Learning rate
tau_pos = 6;                                    % STDP positive time constant in steps
tau_neg = 6;                                    % STDP negative time constant in steps
s_rec = 0;%2^-16;                                  % Synaptic recuperation parameter
Wmax = 5;                                       % Maximum permitted synaptic weight
Wmin = -5;                                      % Minimum permitted synaptic weight

% STDP LUT initialization
LUT_pos = zeros(1,T_BACK+1);
LUT_neg = zeros(1,T_BACK+1);
for i = 1:T_BACK
    LUT_pos(i+1) = double(fi(sigma*A_pos*exp(-i/tau_pos),1,WEIGHT_QUANT,FRAC_QUANT));
    LUT_neg(i+1) = double(fi(sigma*A_neg*exp(-i/tau_neg),1,WEIGHT_QUANT,FRAC_QUANT));
end

% Kernel for the receptive layer
kernel = [ -0.5 -0.25  0.25 -0.25  -0.5...
          -0.25  0.25 0.625  0.25 -0.25...
           0.25 0.625     1 0.625  0.25...
          -0.25  0.25 0.625  0.25 -0.25...
           -0.5 -0.25  0.25 -0.25  -0.5];
% sca = kernel;
sca = fi(kernel,1,24,12);

% Initialization of receptive layer period LUT
period_lut = zeros(1,MAX_FREQ-MIN_FREQ+1);
for i = MIN_FREQ:MAX_FREQ
    tmp = i * AUX_STEPS;
    tmp = tmp / 2^(BITS_FREQ-1);
    tmp = 1 / tmp;
    period_lut(i-MIN_FREQ+1) = round(tmp * STEPS);
end
       
% Word formatting
F_net = fimath('OverflowAction', 'Wrap', 'RoundingMethod', 'Floor', ...
                'ProductMode', 'SpecifyPrecision', 'ProductWordLength', WEIGHT_QUANT, 'ProductFractionLength', FRAC_QUANT, ...
                'SumMode', 'SpecifyPrecision', 'SumWordLength', WEIGHT_QUANT, 'SumFractionLength', FRAC_QUANT ...
                );
F_interp = fimath('OverflowAction', 'Wrap', 'RoundingMethod', 'Floor', ...
                'ProductMode', 'SpecifyPrecision', 'ProductWordLength', BITS_INTERP, 'ProductFractionLength', FRAC_INTERP, ...
                'SumMode', 'SpecifyPrecision', 'SumWordLength', BITS_INTERP, 'SumFractionLength', FRAC_INTERP ...
                );
F_freq = fimath('OverflowAction', 'Wrap', 'RoundingMethod', 'Floor', ...
                'ProductMode', 'SpecifyPrecision', 'ProductWordLength', BITS_INTERP+BITS_FREQ, 'ProductFractionLength', BITS_INTERP, ...
                'SumMode', 'SpecifyPrecision', 'SumWordLength', BITS_INTERP+BITS_FREQ, 'SumFractionLength', BITS_INTERP ...
                );
F_count = fimath('OverflowAction', 'Wrap', 'RoundingMethod', 'Floor', ...
                'ProductMode', 'SpecifyPrecision', 'ProductWordLength', BITS_PER_LUT, 'ProductFractionLength', 0, ...
                'SumMode', 'SpecifyPrecision', 'SumWordLength', BITS_PER_LUT, 'SumFractionLength', 0 ...
                );
            
% Initialization of the SNN
counters = zeros(1,784);    % Each element contains the the input neurons
V = cell(1,length(LS));     % Each cell element contains the membrane potential for the neurons in each layer wo the input layer
for i = 2:length(LS)    % Ignores input layer
    V{i} = Vrest*ones(1,LS(i));
end
SW = cell(1,length(LS));    % Each cell element contains the synaptic weights for the neurons in each layer wo the input layer
for i = 2:length(LS)    % Ignores input layer
    SW{i} = zeros(LS(i-1),LS(i));   % First index = presynaptic neuron, second idx = postsynaptic neuron
end
nextline = '';
buf = fi([],1,WEIGHT_QUANT,FRAC_QUANT);
for i = 2:length(LS)    % Reads the generated weights and stores them in the hardware order
    for j = 1:LS(i)
        filename = strcat('weights/neuron_', int2str(i-1), '_', int2str(j-1), '.txt');
        fileID = fopen(filename, 'r');
        for n = 1:LS(i-1)   % Not compatible if a layer is smaller than the next one, in that case it should be done set by set
            nextline = fgetl(fileID);
            buf.hex = nextline;
            idx = rem(j + n - 2, LS(i-1))+1;    % Compensates the dealineation produced in hardware by the circular register
            SW{i}(idx,j) = double(buf);
        end
        fclose(fileID);
    end
end
sp = cell(1,length(LS));    % Each cell element contains the spike output for each neuron
for i = 1:length(LS)
    sp{i} = zeros(1,LS(i));
end
last_sp = cell(1,length(LS));   % Each cell element contains the stpes since the last firing for each neuron
for i = 1:length(LS)
    last_sp{i} = zeros(1,LS(i));
end

fileID = fopen('x_train.txt', 'r');
nextline = '';
buf = fi([],0,8,8);

for im = 1:25
    
    won = 0;                    % Indicates if a output spike has been already produced for the image
    winners = [];               % Matrix of winner neurons (step, neuron)
    
    % Image reading or initialization
    image = zeros(1,1024);
    
    % for j = 2:32-3      % Random inizialitation
    %     for i = 3:32-2
    %         image(j*32+i) = fi(rand(),0,8,8);
    %     end
    % end
    
    nextline = fgetl(fileID);   % Initialization from file
    for j = 0:31
        for i = 1:32
            nextline = fgetl(fileID);
            buf.hex = nextline;
            %         image(j*32+i) = double(buf);
            image(j*32+i) = buf;
        end
    end
    
    % Period computing
    period = (STEPS+5)*ones(1,784);
    
    for p = 0:784-1
        %     y = floor(p/28);    x = rem(p,28);
        %     conv_pix = zeros(1,25);
        %     for j = 0:4
        %         for i = 1:5
        %             conv_pix(j*5+i) = image((y+j)*32+x+i);
        %         end
        %     end
        %     conv_mult = conv_pix.*sca;    % Multiplication by the kernel
        %     conv_sum = sum(conv_mult);    % Sum of the results
        %     if conv_sum > MAX_INTERP || conv_sum < 0    % Interpolation
        %         interp_res = 1;
        %     else
        %         interp_aux = conv_sum*INTERP_1;
        %         interp_res = interp_aux+INTERP_0;
        %     end
        % %     interp_res = fi(interp_res,F_freq);
        %     freq_aux = interp_res*AUX_STEPS_INV;        % Computation of frequency
        %     freq = freq_aux*(2^(BITS_FREQ-1));
        y = floor(p/28);    x = rem(p,28);
        conv_pix = fi(zeros(1,25),0,8,8);
        for j = 0:4
            for i = 1:5
                conv_pix(j*5+i) = image((y+j)*32+x+i);
            end
        end
        conv_mult = fi(conv_pix.*sca, F_interp);    % Multiplication by the kernel
        conv_sum = fi(sum(conv_mult), F_interp);    % Sum of the results
        if conv_sum > MAX_INTERP || conv_sum < 0    % Interpolation
            interp_res = fi(1, F_interp);
        else
            interp_aux = fi(conv_sum*INTERP_1, F_interp);
            interp_res = fi(interp_aux+INTERP_0, F_interp);
        end
        interp_res = fi(interp_res,F_freq);
        freq_aux = fi(interp_res*AUX_STEPS_INV, F_freq);        % Computation of frequency
        freq = fi(freq_aux*(2^(BITS_FREQ-1)),0,BITS_FREQ,0);
        if freq >= MIN_FREQ && freq <= MAX_FREQ     % Period assignment
            period(p+1) = period_lut(floor(freq)-MIN_FREQ+1);
        else
            period(p+1) = STEPS+5;
        end
    end
    
    % Learning process for one image
    for t = 0:STEPS
        if t == 74
            t
        end
        % Input layer count
        if t < STEPS
            for i = 1:LS(1)
                if counters(i) >= period(i)-1
                    counters(i) = 0;
                else
                    counters(i) = counters(i)+1;
                end
            end
        end
        % STDP weight update
        if t > 0
            for i = 2:length(LS)        % Layer index
                for j = 1:LS(i)         % Local neuron index
                    for k = 1:LS(i-1)   % Previous layer neuron index
                        pos_der = LUT_pos(last_sp{i-1}(k)+1) * sp{i}(j);
                        neg_der = LUT_neg(last_sp{i}(j)+1) * sp{i-1}(k);
                        rec_w = SW{i}(k,j) + s_rec;
                        w_aux = pos_der + neg_der + rec_w;
                        if w_aux > Wmax
                            SW{i}(k,j) = Wmax;
                        elseif w_aux < Wmin
                            SW{i}(k,j) = Wmin;
                        else
                            SW{i}(k,j) = w_aux;
                        end
                    end
                end
            end
        end
        % Lateral inhibition and reset if too low voltage
        for i = 2:length(LS)    % Ignores input layer
            if sum(sp{i} == 1) > 0
                V{i} = Vrest*ones(1,LS(i));
            end
            V{i}(V{i}<Vmin) = Vrest;
        end
        % LIF computation
        if t < STEPS
            for i = 2:length(LS)    % Layer index
                for j = 1:LS(i)     % Local neuron index
                    acc = sum(SW{i}(:,j) .* (sp{i-1})');
                    acc_mult = acc - Kt * V{i}(j);
                    V{i}(j) = V{i}(j) + acc_mult;
                end
            end
        end
        % Last spikes register update
        for i  = 1:length(LS)
            last_sp{i}(sp{i} == 1) = 1;                                                                 % If spike
            last_sp{i}(sp{i} == 0 & last_sp{i} >= T_BACK) = 0;                                          % If not spike and too long since one
            last_sp{i}(sp{i} == 0 & last_sp{i} ~= 0) = last_sp{i}(sp{i} == 0 & last_sp{i} ~= 0) + 1;    % If not spike and a recent one
        end
        % Last step resets
        if t == STEPS
            counters = zeros(1,784);    % Counters reset
            for i = 2:length(LS)        % V reset
                V{i} = Vrest*ones(1,LS(i));
            end
            for i = 1:length(LS)        % Last spikes register reset
                last_sp{i} = zeros(1,LS(i));
            end
            won = 0;
        end
        % Spike generation
        sp{1}(counters == period-1) = 1;
        sp{1}(counters ~= period-1) = 0;
        for i = 2:length(LS)            % Spike if higher than threshold
            sp{i}(V{i} < Vth) = 0;
            sp{i}(V{i} >= Vth) = 1;
        end
        if (~won && sum(sp{length(LS)}))
            for i = 1:LS(length(LS))
                if sp{length(LS)}(i)
                    winners =[winners; t i];
                end
            end
            won = 1;
        end
    end
    
end

fclose(fileID);

save('weights.mat', 'SW');