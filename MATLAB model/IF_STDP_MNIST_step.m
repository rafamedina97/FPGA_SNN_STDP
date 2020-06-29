% This script contains an non-supervised learning algorithm for a Spiking
% Neural Network whose objective is classifying pictures of hand-written
% digits included in the MNIST set.
% The SNN is based on the Leaky Integrate & Fire model of neurons. It
% consists of a input layers with as many neurons as pixels each picture
% has, a hidden layer of a variable number of neurons and a output layers,
% each of which will be assigned to a different digit for recognition.
% The learning algorithm is Spike-Timing-Dependent plasticity.
% In order to increase learning and recognition rates, the images are
% convoluted and interpolated according to a kernel matrix.
% At the end of the script a normal LIF-SNN evaluates the learning
% performed.
% Most of the algorithm parameters are modifiable at the begining of the
% script.


clear all
load('mnist.mat')

% NN Parameters
Ni=784;             % input layer neurons
Nh=20;              % hidden layer neurons
No=10;              % output layer neurons
D=1;                % synapsys delay in STDP
vr = 0;             % resting potential (0 in Shikhargupta AND Iñaki)
Kt = 0.05;          % dt/tau (0 in S, (dt=0.05)/(tau=1)=0.05 in I)
th = 1.25;          % spiking threshold (5 in S, 1.2658213... in I)
vmin = -500;        % minimum potential (-500 in S)
lateral_inhib = 1;  % lateral inhibition activation
% STDP Parameters
sigma = 0.01;       % scales the weight updates (0.1 in S, 0.01 in I)
Apos = 8.5;         % positive weight update (0.8 in S, 8.5 in I)
Aneg = -8.5;        % negative weight update (-0.3 in S, -8.5 in I)
tau_STDP = 8;      % time constant in STDP (in steps) (pos 8, neg 5 in S; pos 8.6, neg 2.6 in I)
dec_STDP = 1-1/tau_STDP;    % decrease of the weights updates each step
wmax = 1.5;           % maximal synaptic strength (1.5 in S, 2 in I)
wmin = -0.02;       % minimal synaptic strength (-1.2 in S, -0.02 in I)
syn_rec_h = 1e-7; % weight increase in every step to potentiate silent neurons
syn_rec_o = 1e-5;     
epochs = 1;        % Loops over the training set (12 in S)
sim_steps = 400;    % Number of simulation steps (200 in S, 1200 in I)
ini_range = 0.4;    % Initial synaptic weight range (from 0 to 0.4 in S)
% Receptive layer Parameters
val_max = 6;       % maximum value for spike train generation (20 in S, 6 in I)
val_min = 1;        % minimum value for spike train generation (1 in S, 1 in I)
kernel = [-0.5  -0.25 0.25  -0.25 -0.5;   % Receptive field convolutional kernel (in S: [-0.5   -0.125 0.125 -0.125 -0.5;
          -0.25 0.25  0.625 0.25  -0.25;  %                                              -0.125 0.125  0.625 0.125  -0.125;
          0.25  0.625 1     0.625 0.25;   %                                              0.125  0.625  1     0.625  0.125;
          -0.25 0.25  0.625 0.25  -0.25;  %                                              -0.125 0.125  0.625 0.125  -0.125;
          -0.5  -0.25 0.25  -0.25 -0.5];  %                                              -0.5   -0.125 0.125 -0.125 -0.5];
kernel_max = 4.5608;
kernel_min = 0;

x_train = x(:,:,1:50000);
y_train = y(1:50000);
x_cv = x(:,:,50001:60000);
y_cv = y(50001:60000);

% Synaptic weights (random initialization) and their derivatives (initially zero)
si = rand(Ni,Nh)*ini_range;
sdi = zeros(Ni,Nh);
sh = rand(Nh,No)*ini_range;
sdh = zeros(Nh,No);

y_result = [];

for e = 1:epochs
    for i = 1:(length(y_aux))
        % Initial values
        STDPi = zeros(Ni,sim_steps+1+D);
        STDPh = zeros(Nh,sim_steps+1+D);
        STDPo = zeros(No,sim_steps+1+D);
        
        vh = vr*ones(Nh,1);                      
        vo = vr*ones(No,1);
        
        % Spike timings
        firings_i=[-D 0];                         
        firings_h=[-D 0];                         
        firings_o=[-D 0];
        
        this_x = x_aux(:,:,i);

        % Receptive field kernel
        conv_x = zeros(28,28);
        for j = 1:28
            for k = 1:28
                conv_x(j,k) = sum(sum(this_x(j:j+4,k:k+4).*kernel));
            end
        end

        conv_x = conv_x(:);         % column 1; column 2; ...
        % Interpolation after the convolution
%         conv_x = conv_x.*((val_max-val_min)/(kernel_max-kernel_min))-kernel_min*((val_max-val_min)/(kernel_max-kernel_min))+val_min;
%         conv_x = conv_x.*((val_max-val_min)/kernel_max)+val_min;

        for j = 1:length(conv_x)
            if (conv_x(j) <= 0)
                conv_x(j) = 0.1;
            else
%                 conv_x(j) = conv_x(j).*((val_max-val_min)/(kernel_max-kernel_min))-kernel_min*((val_max-val_min)/(kernel_max-kernel_min))+val_min;
                conv_x(j) = conv_x(j).*((val_max-val_min)/kernel_max)+val_min;
            end
        end

        spike_train = ceil(sim_steps./conv_x);   % stores the spiking periods assigned to each pixel
        for t=1:sim_steps
            Wh = zeros(Nh,1); Wo = zeros(No,1); % resets the sum of synaptic weights
            
            % Spike checking at each layer
            fired_i = find(rem(t,spike_train) == 0);
            fired_h = find(vh>=th);
            fired_o = find(vo>=th);
            
            % Reset of spiking neurons
            if (lateral_inhib == 0)
                vh(fired_h) = vr;
                vo(fired_o) = vr;
            else
                if(length(fired_h)>=1)
                    vh(:) = vr;
                end
                if(length(fired_o)>=1)
                    vo(:) = vmin; % Avoids learning for the losers output spikes
                end
            end
            
            min_h = find(vh<vmin);  % If the potential of a neuron is too low, gets reset
            min_o = find(vo<vmin);
            vh(min_h) = vr;
            vo(min_o) = vr;
            
            % Stores signma in the position assigned to the neuron spiking and the time it fired (+D for taking into account the delay)
            STDPi(fired_i,t+D) = sigma;
            STDPh(fired_h,t+D) = sigma;
            STDPo(fired_o,t+D) = sigma;
            % These loops increase the synaptic weight derivative if the pre-neuron has spiked recently
            for k=1:length(fired_h)
                sdi(:,fired_h(k))=sdi(:,fired_h(k))+Apos*STDPi(:,t);
            end
            for k=1:length(fired_o)
                sdh(:,fired_o(k))=sdh(:,fired_o(k))+Apos*STDPh(:,t);
            end
            % Appends the time and identity of the neurons fired
            firings_i=[firings_i;t*ones(length(fired_i),1),fired_i];
            firings_h=[firings_h;t*ones(length(fired_h),1),fired_h];
            firings_o=[firings_o;t*ones(length(fired_o),1),fired_o];
            % increases the current of the post-neurons according to the synaptic weights of the fired neurons
            k=size(firings_i,1);
            while firings_i(k,1)==t
                Wh = Wh + si(firings_i(k,2),:)';
                k=k-1;
            end
            % decreases the synaptic weight derivative if the post-neuron has spiked recently
            k=size(firings_i,1);
            while firings_i(k,1)>t-D    
                sdi(firings_i(k,2),:)=sdi(firings_i(k,2),:)+Aneg*STDPh(:,t+D)';
                k=k-1;
            end
            % increases the current of the post-neurons according to the synaptic weights of the fired neurons
            k=size(firings_h,1);
            while firings_h(k,1)==t
                Wo = Wo + sh(firings_h(k,2),:)';
                k=k-1;
            end
            % decreases the synaptic weight derivative if the post-neuron has spiked recently
            k=size(firings_h,1);
            while firings_h(k,1)>t-D
                sdh(firings_h(k,2),:)=sdh(firings_h(k,2),:)+Aneg*STDPo(:,t+D)';
                k=k-1;
            end
            % LIF calculation
            vh=vh+(-(vh-vr)*Kt)+Wh;
            vo=vo+(-(vo-vr)*Kt)+Wo;
            
            % Synaptic weigths update
            pos = find(si(:,:)>=0);
            neg = find(si(:,:)<0);
            si(pos) = min(wmax,syn_rec_h+si(pos)+sdi(pos));  % the syn_rec potentiates the weight of silent neurons
            si(neg) = max(wmin,syn_rec_h+si(neg)+sdi(neg));
            pos = find(sh(:,:)>=0);
            neg = find(sh(:,:)<0);
            sh(pos) = min(wmax,syn_rec_o+sh(pos)+sdh(pos));
            sh(neg) = max(wmin,syn_rec_o+sh(neg)+sdh(neg));
            
            % Reset of the synaptic weight derivatives
            sdi = zeros(Ni,Nh);
            sdh = zeros(Nh,No);
            
            % Exponential decrease of the derivatives weight according to the time constant
            STDPi(:,t+D+1)=dec_STDP*STDPi(:,t+D);
            STDPh(:,t+D+1)=dec_STDP*STDPh(:,t+D);
            STDPo(:,t+D+1)=dec_STDP*STDPo(:,t+D);
        end
        
        % Storing the learning results at the last epoch
        if (e == epochs)
            if size(firings_o,1) > 1
                y_result = [y_result; firings_o(2,2)];
            else
                y_result = [y_result; -1];
            end
        end
        
        subplot(131);
        plot(firings_i(:,1),firings_i(:,2),'.');
        axis([0 sim_steps 0 Ni]); drawnow;
        subplot(132);
        plot(firings_h(:,1),firings_h(:,2),'.');
        axis([0 sim_steps 0 Nh]); drawnow;
        subplot(133);
        plot(firings_o(:,1),firings_o(:,2),'.');
        axis([0 sim_steps 0 No]); drawnow;
    end
end

% Analyse results
% Translation between the spiking output neuron number and the hand-written number guessed (index = handwritten number, content = neuron number)
% Each neuron must be mapped only to one hand-written number
num2res = zeros(10,1);    
for i = 0:9
    ind = find(y_aux == i);
    if(size(find(num2res == mode(y_result(ind))),1) == 0)
        num2res(i+1) = mode(y_result(ind));
    else
        num2res(i+1) = -1;
    end
    
end

rights = 0;
for i = 1:length(y_aux)
    if (y_result(i) ~= -1)
        if (y_result(i) == num2res(y_aux(i)+1))
            rights = rights + 1;
        end
    end
end
rate_train = rights/length(y_aux);

% SNN for testing (without STDP)
y_result = [];
for i = 1:(length(y_cv))
    % Initial values

    vh = vr*ones(Nh,1);                      
    vo = vr*ones(No,1);
    % Spike timings
    firings_i=[-D 0];                         
    firings_h=[-D 0];                         
    firings_o=[-D 0];

    this_x = x_cv(:,:,i);

    % Receptive field kernel
    conv_x = zeros(28,28);
    for j = 1:28
        for k = 1:28
            conv_x(j,k) = sum(sum(this_x(j:j+4,k:k+4).*kernel));
        end
    end
    
    conv_x = conv_x(:);         % column 1; column 2; ...
    % Interpolation after the convolution
    %         conv_x = conv_x.*((val_max-val_min)/(kernel_max-kernel_min))-kernel_min*((val_max-val_min)/(kernel_max-kernel_min))+val_min;
    %         conv_x = conv_x.*((val_max-val_min)/kernel_max)+val_min;
    
    for j = 1:length(conv_x)
        if (conv_x(j) <= 0)
            conv_x(j) = 0.1;
        else
            %                 conv_x(j) = conv_x(j).*((val_max-val_min)/(kernel_max-kernel_min))-kernel_min*((val_max-val_min)/(kernel_max-kernel_min))+val_min;
            conv_x(j) = conv_x(j).*((val_max-val_min)/kernel_max)+val_min;
        end
    end
        
    spike_train = ceil(sim_steps./conv_x);   % the image is the input
    for t=1:sim_steps
        Wh = zeros(Nh,1); Wo = zeros(No,1);

        fired_i = find(rem(t,spike_train) == 0);
        fired_h = find(vh>=th);
        fired_o = find(vo>=th);

        if (lateral_inhib == 0)
            vh(fired_h) = vr;
            vo(fired_o) = vr;
        else
            if(length(fired_h)>=1)
                vh(:) = vr;
            end
            if(length(fired_o)>=1)
                vo(:) = vmin; % Avoids learning for the losers output spikes
            end
        end

        min_h = find(vh<vmin);  % If the potential of a neuron is too low, gets reset
        min_o = find(vo<vmin);
        vh(min_h) = vr;
        vo(min_o) = vr;

        firings_i=[firings_i;t*ones(length(fired_i),1),fired_i];
        firings_h=[firings_h;t*ones(length(fired_h),1),fired_h];
        firings_o=[firings_o;t*ones(length(fired_o),1),fired_o];
        % increases the current of the post-neurons according to the synaptic weights of the fired neurons
        k=size(firings_i,1);
        while firings_i(k,1)==t
            Wh = Wh + si(firings_i(k,2),:)';
            k=k-1;
        end
        % increases the current of the post-neurons according to the synaptic weights of the fired neurons
        k=size(firings_h,1);
        while firings_h(k,1)==t
            Wo = Wo + sh(firings_h(k,2),:)';
            k=k-1;
        end
        vh=vh+(-(vh-vr)*Kt)+Wh;
        vo=vo+(-(vo-vr)*Kt)+Wo;

    end

    if size(firings_o,1) > 1
        y_result = [y_result; firings_o(2,2)];
    else
        y_result = [y_result; -1];
    end
end

rights = 0; 
for i = 1:length(y_cv)
    if (y_result(i) ~= -1)
        if (y_result(i) == num2res(y_cv(i)+1))
            rights = rights + 1;
        end
    end
end
rate_cv = rights/length(y_cv);