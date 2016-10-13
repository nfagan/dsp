function [coherence,freq] = SignalObject__coherence(a_signals,b_signals,varargin)

params = struct(...
    'takeMean', true ...
);

params = parsestruct(params,varargin);
params = paraminclude('Params__signal_processing',params);

if ~isa(b_signals,'SignalObject')
    error('The second input must be a signal object');
end

fs = a_signals.fs;

if fs ~= b_signals.fs;
    error('Sampling rates must match between objects');
end

a_signals = windowconcat(a_signals);
b_signals = windowconcat(b_signals);

take_mean = params.takeMean;
freqs = params.freqs;

for i = 1:length(a_signals);
    one_window_a = a_signals{i};
    one_window_b = b_signals{i};
    
    one_window_a = one_window_a';
    one_window_b = one_window_b';
    
    [C,f] = mscohere(one_window_a,one_window_b,[],[],freqs,fs);
    
    if ( size(f,1) < size(f,2) ); f = f'; end;    %   store column-wise
    
    if take_mean
        C = mean(C,2); 
        coherence(:,i) = C;
        freq(:,i) = f;
    else
        coherence{i} = C;
        freq(:,i) = f;
    end
end

% params.tapers = [11 5];
% params.pad = -1;
% params.Fs = fs;
% params.fpass = [0 max_freq];
    
    

