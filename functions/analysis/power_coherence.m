function power_coherence()

signals = SignalObject(data_object_input,5e3);

%% raw power

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

%% normalized power

norm_method = 'divide';
norm_epoch = 'mag';

within = {'regions','trialtypes','outcomes','epochs','administration'};

[indices, combs] = getindices(signals,within);

region_ind = strcmp(within,'regions');
epoch_ind = strcmp(within,'epochs');

for i = 1:length(indices)
    to_norm = signals(indices{i});
    norm_by = signals(signals == [combs(i,~epoch_ind) {norm_epoch}]);
    
    ref_to_norm = signals(signals == [combs(i,~region_ind) {'ref'}]);
    ref_to_norm_by = signals(signals == [combs(i,~(region_ind | epoch_ind)) {norm_epoch} {'ref'}]);
    
    to_norm = to_norm - ref_to_norm;
    norm_by = norm_by - ref_to_norm_by;
    
    power = norm_power(to_norm,norm_by,'normMethod',norm_method);
    
    labels = labelbuilder(to_norm,combs(i,:));
    
    if i == 1
        store_norm_power = DataObject({power},labels);
    else
        store_norm_power = [store_norm_power; DataObject({power},labels)];
    end
    
end

%% coherence

within = {'trialtypes','outcomes','epochs','administration'};

[indices, combs] = getindices(signals,within);

for i = 1:length(indices)
    limited = signals(indices{i});
    
    acc = limited(limited == 'acc');
    bla = limited(limited == 'bla');
    ref = limited(limited == 'ref');
    
    acc = acc - ref;
    bla = bla - ref;
    
    coh = coherence(bla,acc);
    
    labels = labelbuilder(acc,combs(i,:));
    
    if i == 1
        store_coherence = DataObject({coh},labels);
    else
        store_coherence = [store_coherence; DataObject({coh},labels)];
    end
    
end


