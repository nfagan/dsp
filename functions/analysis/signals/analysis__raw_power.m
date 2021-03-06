function [store_power, f] = analysis__raw_power(signals,varargin)

params = struct(...
    'within',{{'regions','trialtypes','outcomes','epochs','administration'}}, ...
    'takeMean',true ...
    );

params = paraminclude('Params__signal_processing',params);
params = parsestruct(params,varargin);

passed_params = struct2varargin(params,'within');

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
    
    if isempty(ref) && params.subtractReference
        continue;
    end
    
    if params.subtractReference
        fixed = real - ref;
    else fixed = real;
    end
    
    [power, f] = raw_power(fixed,passed_params{:});
    
    labels = labelbuilder(real,combs(i,:));
    
    store_power = [store_power; DataObject({power},labels)];
end

store_power = SignalObject(store_power, signals.fs, signals.time);

end