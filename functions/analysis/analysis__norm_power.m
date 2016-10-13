function store_norm_power = analysis__norm_power(target,base,varargin)

%{
    parse inputs
%}

params = struct(...
    'within',{{'regions','trialtypes','outcomes','epochs','administration','drugs','monkeys'}}, ...
    'normMethod','divide', ...
    'normEpoch', 'magcue', ...
    'trialByTrial', false ...
);
exclude = {'within','normEpoch'};

params = paraminclude('Params__signal_processing',params);
params = parsestruct(params,varargin);

passed_params = struct2varargin(params,exclude);

norm_epoch = params.normEpoch;

within = params.within;

%{
    separate reference electrode signals
%}

ref_target = target(target == 'ref');
ref_base = base(base == 'ref');

target = target(target ~= 'ref'); 
base = base(base ~= 'ref');

if (isempty(ref_target) || isempty(ref_base)) && params.subtractReference
    error('No ''ref'' signals are present in the object');
end

[indices, combs] = getindices(target,within);

region_ind = strcmp(within,'regions');
epoch_ind = strcmp(within,'epochs');
outcome_ind = strcmp(within,'outcomes');

if ~params.collapseBaselineOutcomes
    outcome_ind = false(size(outcome_ind));
end

store_norm_power = DataObject();

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    to_norm = target(indices{i});
    norm_by = base(base == [combs(i,~(epoch_ind | outcome_ind)) {norm_epoch}]);
    
    if params.subtractReference
        ref_to_norm = ref_target(ref_target == [combs(i,~region_ind)]);
        ref_to_norm_by = ref_base(ref_base == ...
            [combs(i,~(region_ind | epoch_ind | outcome_ind)) {norm_epoch}]);

        to_norm = to_norm - ref_to_norm;
        norm_by = norm_by - ref_to_norm_by;
    end
    
    power = norm_power(to_norm,norm_by,passed_params{:});    
    
    labels = labelbuilder(to_norm,combs(i,:));
    
    store_norm_power = [store_norm_power; DataObject({power},labels)];
    
end

store_norm_power = SignalObject(store_norm_power,target.fs,target.time);

if params.trialByTrial
    store_norm_power = windowmean(store_norm_power);
end

end