function [coherence,freq] = SignalObject__coherence(a_signals,b_signals,varargin)

params = struct(...
    'takeMean', true ...
);

params = parsestruct(params,varargin);
params = paraminclude('Params__signal_processing',params);

if ~isa(b_signals,'SignalObject')
    error('The second input must be a signal object');
end

a_signals = a_signals.data;
b_signals = b_signals.data;

take_mean = params.takeMean;
% max_freq = params.maxFreq;
freqs = params.freqs;

fs = obj.fs;

for i = 1:length(a_signals);
    one_window_a = a_signals{i};
    one_window_b = b_signals{i};
    
    one_window_a = one_window_a';
    one_window_b = one_window_b';
    
    [C,f] = mscohere(one_window_a,one_window_b,[],[],freqs,fs);
    
    w = f';
    
    if take_mean
        Cxy = mean(C,2); 
        coherence(:,i) = Cxy;
        freq(:,i) = w;
    else
        coherence{i} = C;
        freq(:,i) = w;
    end
end

% params.tapers = [11 5];
% params.pad = -1;
% params.Fs = fs;
% params.fpass = [0 max_freq];
    
    

