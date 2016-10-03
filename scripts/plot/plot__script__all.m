
plotdirectory = fullfile(pathfor('secondGrantPlots'),'100316');

set(0,'DefaultFigureVisible','off');

%% power / norm power

type = 'testing_norm_power_methods';
append = '_subtract_trial_by_trial';
within = {'regions','epochs','administration','trialtypes','outcomes'};

[indices,combs] = getindices(data,within);

for i = 1:length(indices)
    extr = data(indices{i});
    
    drug = char(unique(extr('drugs')));
    admin = char(unique(extr('administration')));
    trial = char(unique(extr('trialtypes')));
    outcome = char(unique(extr('outcomes')));
    region = char(unique(extr('regions')));
    epoch = char(unique(extr('epochs')));
    
%     filename = sprintf('%s_%s_%s',region,trial,outcome);
    
%     filepath = fullfile(plotdirectory,type,drug,admin,epoch,filename);

    filename = sprintf('%s_%s_%s_%s_%s_%s',drug,admin,epoch,region,trial,outcome);
    
    if ~strcmp(append,''); filename = [filename append]; end
    
    filepath = fullfile(plotdirectory,type,filename);
    
    plot__spectrogram(extr,...
        'freqLimits',  [0 70], ...
        'fromTo',   [min(data.time) max(data.time)], ...
        'timeSeries',data.time, ...
        'freqs',    [0:200], ...
        'savePlot', true, ...
        'logTransform', false, ...
        'savePath', filepath,...
        'filetype', 'png', ...
        'clims',    [-8e-6 1e-6], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Power', ...
        'title',    sprintf('%s - %s - %s - %s',region,outcome,admin,drug) ...
        );
end

% close all;

%.5 1.3
% .5e-4 8e-4

%% coherence

type = 'coherence_ot_minus_saline';
% type = 'subtracted_coherence_all';
% data = oxy_minus_sal;
% data = sal.coh_subtracted;
% data = all(all == 'other_minus_none');
% data = self_minus_both;
% data = coh_self_minus_both;
% data = sal_coh.both_minus_self(sal_coh.both_minus_self == 'choice');
% data = all.oxy.coh_subtracted(all.oxy.coh_subtracted == 'other_minus_none');
data = other_minus_none;
within = {'epochs','drugs','trialtypes','outcomes'};

[indices,combs] = getindices(data,within);

for i = 1:length(indices)
    extr = data(indices{i});
    
    drug = char(unique(extr('drugs')));
    admin = char(unique(extr('administration')));
    trial = char(unique(extr('trialtypes')));
    outcome = char(unique(extr('outcomes')));
    epoch = char(unique(extr('epochs')));
    
    filename = sprintf('%s_%s',trial,outcome);
    
    filepath = fullfile(plotdirectory,type,drug,admin,epoch,filename);

    plot__spectrogram(extr,...
        'maxFreq',  70, ...
        'fromTo',   [-300 700], ...
        'savePlot', true, ...
        'savePath', filepath,...
        'filetype', 'epsc', ...
        'clims',    [-.06 .06], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Coherence', ...
        'title',    sprintf('%s - %s',admin,drug) ...
        );
end





