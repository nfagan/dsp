function [power,freqs] = SignalObject__norm_power(to_norm,baseline,varargin)

params = struct(...
    'normMethod','subtract', ...
    'trialByTrial',false ...
    );

exclude = fieldnames(params);

params = parsestruct(params,varargin);
params = paraminclude('Params__signal_processing',params);

passed_params = struct2varargin(params,exclude);

%{
    after parsing input args ...
%}

freqs = params.freqs;
method = params.normMethod;

base_power = raw_power(baseline,passed_params{:});

if ~params.trialByTrial
    base_power = mean(base_power,2); % Get the row-mean (per-trial mean) for the baseline-period
end

power = zeros(length(freqs),length(to_norm));
% power = cell(1,length(to_norm));
for i = 1:count(to_norm,2);
    
    [to_norm_power,freqs] = raw_power(to_norm(:,i),passed_params{:});
    
    if ~params.trialByTrial
        to_norm_power = mean(to_norm_power,2);  % Get the row-mean (per-trial mean) for this 
                                                % time-bin (time window)
    end
    
    if strcmp(method,'subtract');
        normPower = to_norm_power-base_power; % Normalize it by the baseline-power
    else   
        normPower = to_norm_power ./ base_power;
    end
    
    power(:,i) = mean(normPower,2); % Store per-window
%     power{i} = normPower;
    
end
    
    
    