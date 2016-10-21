function [power,freqs] = SignalObject__norm_power(to_norm,baseline,varargin)

params = struct(...
    'normMethod','divide', ...
    'trialByTrial', false, ...
    'preserveTrials', false ...
    );

exclude = fieldnames(params);

params = paraminclude('Params__signal_processing',params);
params = parsestruct(params,varargin);

passed_params = struct2varargin(params,exclude);

%{
    after parsing input args ...
%}

freqs = params.freqs;
method = params.normMethod;

base_power = raw_power(baseline, passed_params{:}, 'takeMean', false);
base_power = base_power{1};

if params.preserveTrials
    power = cell( 1, length(to_norm) );
else
    power = zeros( length(freqs), length(to_norm) );
end

if ~params.trialByTrial
    base_power = repmat( mean(base_power, 2), 1, count(to_norm, 1) );
end

for i = 1:count(to_norm, 2);
    
    onewindow = to_norm; onewindow.data = onewindow.data(:,i);

    [to_norm_power,freqs] = raw_power( onewindow, passed_params{:}, 'takeMean', false );
    to_norm_power = to_norm_power{1};
    
    if strcmp( method, 'subtract' )
        normedPower = to_norm_power - base_power;
    else normedPower = to_norm_power ./ base_power;
    end
    
    if params.preserveTrials
        power(:,i) = {normedPower};
    else
        power(:,i) = mean(normedPower, 2);
%         power(:,i) = median(normedPower, 2);
    end
    
end


% passed_params = struct2varargin(params, {'normMethod','trialByTrial'});

% if params.trialByTrial
%     passed_params = [passed_params {'takeMean'} {false}];
% end


% if ~params.trialByTrial && params.takeMean
% %     base_power = mean(base_power,2); % Get the row-mean (per-trial mean) for the baseline-period
%     base_power = repmat( mean(base_power,2), 1, count(to_norm,1) );
%     power = zeros(length(freqs),length(to_norm));
% else
%     power = cell(1,length(to_norm));
%     base_power = base_power{1};
% end



    %%% end debug;
    
%     [to_norm_power,freqs] = raw_power(onewindow,passed_params{:});    
    
    
%     if ~params.trialByTrial
%         to_norm_power = mean(to_norm_power,2);  % Get the row-mean (per-trial mean) for this 
%                                                 % time-bin (time window)
%     else to_norm_power = to_norm_power{1};
%     end
%     
%     if strcmp(method,'subtract');
%         normPower = to_norm_power - base_power; % Normalize it by the baseline-power
%     else normPower = to_norm_power ./ base_power;
%     end
%     
%     if ~params.trialByTrial && params.takeMean
%         power(:,i) = mean(normPower,2); % Store per-window
%     else power(:,i) = {normPower};
%     end
    
    
    