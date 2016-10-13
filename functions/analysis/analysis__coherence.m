function store_coh = analysis__coherence(signals,varargin)

params = struct(...
    'within',{{'administration','trialtypes','outcomes','drugs','epochs','monkeys'}} ...
);
params = paraminclude('Params__signal_processing', params);
params = parsestruct(params,varargin);

within = params.within;

[indices, combs] = getindices(signals,within);

store_coh = DataObject();

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    acc = signals(signals == [combs(i,:) {'acc'}]);
    bla = signals(signals == [combs(i,:) {'bla'}]);
    
    if params.subtractReference
        ref = signals(signals == [combs(i,:) {'ref'}]);
        acc = acc - ref;
        bla = bla - ref;
    end
    
    coh = coherence(bla,acc);
    
    labels = labelbuilder(acc,combs(i,:));
    
    store_coh = [store_coh; DataObject({coh},labels)];
    
end

store_coh = SignalObject(store_coh, signals.fs, signals.time);

end

