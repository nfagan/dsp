
plotdirectory = fullfile(pathfor('secondGrantPlots'),'092016');

set(0,'DefaultFigureVisible','off');

%% power / norm power

type = 'raw_power_collapsed_across_pre_and_post';
% data = sal.npower_post_minus_pre;
% data = targ_power(targ_power == 'other');
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
    
    filename = sprintf('%s_%s_%s',region,trial,outcome);
    
    filepath = fullfile(plotdirectory,type,drug,admin,epoch,filename);
    
    plot__spectrogram(extr,...
        'maxFreq',  70, ...
        'fromTo',   [-300 700], ...
        'savePlot', true, ...
        'savePath', filepath,...
        'filetype', 'png', ...
        'clims',    [.5e-4 6.5e-4], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Normalized Power', ...
        'title',    sprintf('%s - %s',admin,drug) ...
        );
end

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





