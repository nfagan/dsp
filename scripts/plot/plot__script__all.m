
plotdirectory = '/Volumes/My Passport/NICK/Chang Lab 2016/dsp/plots/091516';

set(0,'DefaultFigureVisible','off');

%% power / norm power

type = 'norm_power';
data = npower;
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
    
    filename = sprintf('%s_%s_%s_%s',region,trial,outcome);
    
    filepath = fullfile(plotdirectory,type,drug,admin,epoch,filename);
    
    plot__spectrogram(extr,...
        'maxFreq',  100, ...
        'savePlot', true, ...
        'savePath', filepath,...
        'clims',    [], ...
        'xLabel',   sprintf('Time (ms) from %s',epoch), ...
        'yLabel',   'Normalized Power' ...
        );
end

%% coherence







