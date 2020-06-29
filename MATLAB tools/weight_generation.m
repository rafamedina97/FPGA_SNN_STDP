clear all

LAYERS = [784 20 10];

INT_QUANT = 8;                          % Fixed-point number of integer bits for data in LIF and STDP
FRAC_QUANT = 16;                        % Fixed-point number of fractional bits for data in LIF and STDP
WEIGHT_QUANT = INT_QUANT + FRAC_QUANT;  % Fixed-point total number of bits for data in LIF and STDP
ini_range = 0.4;                        % Range for the random weight initialization
ini_offset = 0;                         % Left bound for the random weight initialization

rng(10)     % Set the seed for the weight generation

for i = 2:length(LAYERS)
    for j = 1:LAYERS(i)
        filename = strcat('weights/neuron_', int2str(i-1), '_', int2str(j-1), '.txt');
        fileID = fopen(filename, 'w');
        weights = fi(rand(LAYERS(i-1),1)*ini_range+ini_offset, 1, WEIGHT_QUANT, FRAC_QUANT);
        %hex_w = hex(weights)
        for n = 1:length(weights)
            fprintf(fileID, '%s\n', hex(weights(n)));
        end
        fclose(fileID);
    end
end