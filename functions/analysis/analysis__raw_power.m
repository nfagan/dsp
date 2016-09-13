function store_power = analysis__raw_power(signals)

within = {'regions','trialtypes','outcomes','epochs','administration','days'};

[indices, combs] = getindices(signals,within);

region_ind = strcmp(within,'regions');

for i = 1:length(indices)
    
    real = signals(indices{i});
    ref = signals(signals == [{'ref'} combs(i,~region_ind)]);
    
    if isempty(ref)
        continue;
    end
    
    fixed = real - ref;
    
    power = raw_power(fixed);
    
    labels = labelbuilder(real,combs(i,:));
    
    if i == 1
        store_power = DataObject({power},labels);
    else store_power = [store_power; DataObject({power},labels)];
    end
    
end

end