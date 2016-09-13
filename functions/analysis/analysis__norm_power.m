function store_norm_power = analysis__norm_power(signals)

norm_method = 'divide';
norm_epoch = 'magcue';

within = {'regions','trialtypes','outcomes','epochs','administration'};

[indices, combs] = getindices(signals,within);

region_ind = strcmp(within,'regions');
epoch_ind = strcmp(within,'epochs');

for i = 1:length(indices)
    
    to_norm = signals(indices{i});
    norm_by = signals(signals == [combs(i,~epoch_ind) {norm_epoch}]);
    
    ref_to_norm = signals(signals == [combs(i,~region_ind) {'ref'}]);
    ref_to_norm_by = signals(signals == ...
        [combs(i,~(region_ind | epoch_ind)) {norm_epoch} {'ref'}]);
    
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


end