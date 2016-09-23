function store_power = analysis__raw_power(signals,varargin)

params = struct(...
    'within',{{'regions','trialtypes','outcomes','epochs','administration','days'}} ...
    );
params = parsestruct(params,varargin);

within = params.within;

reference = signals(signals == 'ref');
signals = signals(signals ~= 'ref');

[indices, combs] = getindices(signals,within);

region_ind = strcmp(within,'regions');

store_power = DataObject();

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    real = signals(indices{i});
    ref = reference(reference == combs(i,~region_ind));
    
    if isempty(ref)
        continue;
    end
    
    fixed = real - ref;
    
    power = raw_power(fixed);
    
    labels = labelbuilder(real,combs(i,:));
    
    store_power = [store_power; DataObject({power},labels)];
end

end