function [power,frequency] = SignalObject__raw_power(obj,varargin)

params = struct(...
    'takeMean', true ...
);

params = parsestruct(params,varargin);
params = paraminclude('Params__signal_processing.mat',params);

n_tapers = params.nMultitapers;
method = params.method;
freqs = params.freqs;
take_mean = params.takeMean;

fs = obj.fs;
signals = obj.data;

if ~iscell(signals)
    signals = {signals};
end

nw = (n_tapers + 1)/2;

for i = 1:length(signals);
    
    one_window = signals{i};
    one_window = one_window';
    
    if strcmp(method,'periodogram');
        [pxx,w] = periodogram(one_window,[],freqs,fs);
    elseif strcmp(method,'multitaper')           
%         [pxx,w] = pmtm(one_window,(5/2),freqs,fs);
        [pxx,w] = pmtm(one_window,nw,freqs,fs);
    else
        error('Unrecognized method ''%s''',method);
    end
    
    if take_mean
        pxx = mean(pxx,2);
        power(:,i) = pxx;
        frequency(:,i) = w;
    else
        power{i} = pxx;
        frequency{i} = w;
    end
end
