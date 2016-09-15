function store_norm_power = analysis__norm_power(target,base)

norm_method = 'divide';
norm_epoch = 'magcue';

within = {'regions','trialtypes','outcomes','epochs','administration'};

%{
    separate reference electrode signals
%}

ref_target = target(target == 'ref');
ref_base = base(base == 'ref');

target = target(target ~= 'ref'); 
base = base(base ~= 'ref');

[indices, combs] = getindices(target,within);

region_ind = strcmp(within,'regions');
epoch_ind = strcmp(within,'epochs');

store_norm_power = DataObject();

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    to_norm = target(indices{i});
    norm_by = base(base == [combs(i,~epoch_ind) {norm_epoch}]);
    
    ref_to_norm = ref_target(ref_target == [combs(i,~region_ind)]);
    ref_to_norm_by = ref_base(ref_base == ...
        [combs(i,~(region_ind | epoch_ind)) {norm_epoch}]);
    
    to_norm = to_norm - ref_to_norm;
    norm_by = norm_by - ref_to_norm_by;
    
    power = norm_power(to_norm,norm_by,'normMethod',norm_method);
    
    labels = labelbuilder(to_norm,combs(i,:));
    
    store_norm_power = [store_norm_power; DataObject({power},labels)];
    
end


end