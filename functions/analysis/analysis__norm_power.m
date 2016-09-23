function store_norm_power = analysis__norm_power(target,base,varargin)

params = struct(...
    'within',{{'regions','trialtypes','outcomes','epochs','administration'}}, ...
    'normMethod','divide', ...
    'normEpoch', 'magcue', ...
    'trialByTrial', false ...
);

params = parsestruct(params,varargin);

norm_method = params.normMethod;
norm_epoch = params.normEpoch;

within = params.within;

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
    
    power = norm_power(to_norm,norm_by,...
        'normMethod',norm_method,'trialByTrial',params.trialByTrial);
    
    labels = labelbuilder(to_norm,combs(i,:));
    
    store_norm_power = [store_norm_power; DataObject({power},labels)];
    
end


end