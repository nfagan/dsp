function store = analysis__sample_size(pow,varargin)

params = struct(...
    'timeSeries', [-1000:50:1000], ...
    'timeLimits', [0 150], ...
    'freqLimits', [10 30], ...
    'outcomes',{{'self','other'}} ...
);

params = parsestruct(paraminclude('Params__signal_processing',params),varargin);

freqs = params.freqs;
time = params.timeSeries;

freq_index = freqs >= params.freqLimits(1) & freqs <= params.freqLimits(2);
time_index = time >= params.timeLimits(1) & time <= params.timeLimits(2);

tosub = pow(pow == params.outcomes{1});
sub = pow(pow == params.outcomes{2});

tosub('outcomes') = [params.outcomes{1} 'minus' params.outcomes{2}];
sub('outcomes') = [params.outcomes{1} 'minus' params.outcomes{2}];

subtracted = tosub - sub;
subtracted.data = cellfun(@(x) mean(mean(x(freq_index,time_index))),...
    subtracted.data);

allfields = subtracted.label_fields;
allfields = allfields(~strcmp(allfields,'days'));

[indices, combs] = getindices(subtracted,allfields);

store = layeredstruct({{'means','devs'}},DataObject());

for i = 1:numel(indices)
    not_within_day = subtracted(indices{i});
    
    means = mean(not_within_day);
    devs = std(not_within_day);
    
    labs = labelbuilder(not_within_day,combs(i,:));
    
    store.means = [store.means; DataObject(means,labs)];
    store.devs = [store.devs; DataObject(devs,labs)];
end

end