function store_coh = analysis__coherence(signals)

within = {'trialtypes','outcomes'};

[indices, combs] = getindices(signals,within);

store_coh = DataObject();

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    acc = signals(signals == [combs(i,:) {'acc'} {'reward'}]);
    bla = signals(signals == [combs(i,:) {'bla'} {'reward'}]);
    ref = signals(signals == [combs(i,:) {'ref'} {'reward'}]);
    
    acc = acc - ref; 
    bla = bla - ref;
    
    coh = coherence(bla,acc);
    
    labels = labelbuilder(acc,combs(i,:));
    
    store_coh = [store_coh; DataObject({coh},labels)];
    
end

end

