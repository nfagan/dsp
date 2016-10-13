function [power,freqs] = SignalObject__norm_power(to_norm,baseline,varargin)

params = struct(...
    'normMethod','divide', ...
    'trialByTrial',false ...
    );

exclude = fieldnames(params);

params = paraminclude('Params__signal_processing',params);
params = parsestruct(params,varargin);

passed_params = struct2varargin(params,exclude);

if params.trialByTrial
    passed_params = [passed_params {'takeMean'} {false}];
end

%{
    after parsing input args ...
%}

freqs = params.freqs;
method = params.normMethod;

base_power = raw_power(baseline,passed_params{:});

if ~params.trialByTrial
    base_power = mean(base_power,2); % Get the row-mean (per-trial mean) for the baseline-period
    power = zeros(length(freqs),length(to_norm));
else
    power = cell(1,length(to_norm));
    base_power = base_power{1};
end

for i = 1:count(to_norm,2);
    
    onewindow = to_norm; onewindow.data = onewindow.data(:,i);
    
    [to_norm_power,freqs] = raw_power(onewindow,passed_params{:});
    
    if ~params.trialByTrial
        to_norm_power = mean(to_norm_power,2);  % Get the row-mean (per-trial mean) for this 
                                                % time-bin (time window)
    else to_norm_power = to_norm_power{1};
    end
    
    if strcmp(method,'subtract');
        normPower = to_norm_power - base_power; % Normalize it by the baseline-power
    else normPower = to_norm_power ./ base_power;
    end
    
    if ~params.trialByTrial
        power(:,i) = mean(normPower,2); % Store per-window
    else power(:,i) = {normPower};
    end
    
end
    
    
    