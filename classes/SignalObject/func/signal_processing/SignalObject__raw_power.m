function [power,frequency] = SignalObject__raw_power(obj,varargin)

params = struct(...
    'takeMean', true ...
);

params = paraminclude('Params__signal_processing.mat',params);
params = parsestruct(params,varargin);

%   Parse inputs from params struct

n_tapers = params.nMultitapers;
method = params.method;
freqs = params.freqs;
take_mean = params.takeMean;

fs = obj.fs;

nw = (n_tapers + 1)/2;

%   Concatenate signals if they are windowed

if strcmp(obj.dtype,'cell')
    signals = windowconcat(obj);
else
    signals = obj.data;
end

if take_mean
    power = zeros(numel(freqs),numel(signals));
    frequency = zeros(numel(freqs),numel(signals));
else
    power = cell(1,numel(signals));
    frequency = cell(1,numel(signals));
end

%{
    remove outlier signals
%}

signals = exclude(signals,[-.5 .5]);

%{
    calculate power within each window
%}

for i = 1:length(signals);
    
    one_window = signals{i};
    one_window = one_window';
    
%     one_window = one_window(:,1:5);
    
    if strcmp(method,'periodogram');
        [pxx,w] = periodogram(one_window,[],freqs,fs);
    elseif strcmp(method,'multitaper')           
        [pxx,w] = pmtm(one_window,nw,freqs,fs);
    else
        error('Unrecognized method ''%s''',method);
    end
    
%     pxx = pxx'; % if using one trial
    
    if take_mean
        pxx = mean(pxx,2);
        power(:,i) = pxx;
        frequency(:,i) = w;
    else
        power{i} = pxx;
        frequency{i} = w;
    end
end

end

%{
    reject trials in which any signals are above this threshold
%}

function fixed = exclude(signals,limits)

assert(numel(limits) == 2,'Limits must have two elements');

ind = false(size(signals{1}));
for i = 1:numel(signals)
    out_of_bounds = signals{i} < limits(1) | signals{i} > limits(2);
    ind = ind | out_of_bounds;
end

ind = sum(ind,2) == 0;

fprintf('\nExcluded %f percent',100 - perc(ind));

fixed = cellfun(@(x) x(ind,:), signals, 'UniformOutput', false);

    
end
