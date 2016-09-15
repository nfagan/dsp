
plotdirectory = fullfile(pathfor('secondGrantPlots'),'091516');

set(0,'DefaultFigureVisible','off');

%% power / norm power

type = 'norm_power';
data = oxy.npower_post_minus_pre(oxy.npower_post_minus_pre == 'none');
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
        'maxFreq',  100, ...
        'fromTo',   [-500 1000], ...
        'savePlot', true, ...
        'savePath', filepath,...
        'clims',    [-4 4], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Normalized Power', ...
        'title',    sprintf('%s - %s',admin,drug) ...
        );
end

%% coherence







