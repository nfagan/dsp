
plotdirectory = fullfile(pathfor('secondGrantPlots'),'091616');

set(0,'DefaultFigureVisible','off');

%% power / norm power

type = 'norm_power';
data = sal.npower_post_minus_pre;
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
        'filetype', 'epsc', ...
        'clims',    [-3 3], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Normalized Power', ...
        'title',    sprintf('%s - %s',admin,drug) ...
        );
end

%% coherence

type = 'coherence';
% data = oxy_minus_sal;
% data = sal.coh_subtracted;
data = all(all == 'other_minus_none');
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
        'clims',    [-.02 .12], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Coherence', ...
        'title',    sprintf('%s - %s',admin,drug) ...
        );
end





