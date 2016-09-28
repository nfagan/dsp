function [power,frequency] = SignalObject__raw_power(obj,varargin)

assert(~isempty(obj),'No signals exist in the object');

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

% nw = (n_tapers + 1)/2;
% nw = 1.5;
nw = 2;

%{
    define inputs for chronux structure
%}

chronux_params.Fs = fs;
chronux_params.tapers = [1.5 2];
chronux_params.fpass = [freqs(1) freqs(end)];
chronux_params.trialave = take_mean;

%   Concatenate signals if they are windowed

if strcmp(obj.dtype,'cell')
    signals = windowconcat(obj);
else
    signals = obj.data;
end

if take_mean && ~strcmp(method,'chronux')
    power = zeros(numel(freqs),numel(signals));
    frequency = zeros(numel(freqs),numel(signals));
elseif ~take_mean
    power = cell(1,numel(signals));
    frequency = cell(1,numel(signals));
end

%{
    remove outlier signals
%}

% signals = exclude(signals,[-.5 .5]);

%{
    calculate power within each window
%}

for i = 1:length(signals);
    
    one_window = signals{i};
    one_window = one_window';
    
    if params.subtractBinMean
        mean_within_bin = mean(one_window);

        for k = 1:size(one_window,1)
            one_window(k,:) = one_window(k,:) - mean_within_bin;
        end
    end
    
    if strcmp(method,'periodogram');
        [pxx,w] = periodogram(one_window,[],freqs,fs);
    elseif strcmp(method,'multitaper')           
        [pxx,w] = pmtm(one_window,nw,freqs,fs);
    elseif strcmp(method,'chronux')
        [pxx,w] = mtspectrumc(one_window,chronux_params);
    else
        error('Unrecognized method ''%s''',method);
    end
    
%     pxx = pxx'; % if using one trial
    
    if take_mean
        pxx = mean(10.*log10(pxx),2); %  NOTE: changed to log10 calculation
        power(:,i) = pxx;
        frequency(:,i) = w;
    elseif ~take_mean
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
