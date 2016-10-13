to_norm.mag = process(hitch.magcue,50,150);
to_norm.choice = process(hitch.targetacquire,50,150);
to_norm.reward = process(hitch.reward,50,150);

fields = fieldnames(to_norm);
for i = 1:numel(fields)
    to_norm.(fields{i})('administration') = 'all';
    to_norm.(fields{i}) = remove(to_norm.(fields{i}),'cued');
end

%%

epochs = fields(~strcmp(fields,'mag'));

for i = 1:numel(epochs)

normed.subtract_by_mean_baseline_within_outcome.(epochs{i}) = ... 
    analysis__norm_power(to_norm.(epochs{i}), to_norm.mag, ...
    'normMethod', 'subtract', ...
    'method', 'multitaper', ...
    'trialByTrial', false, ...
    'collapseBaselineOutcomes', false ...
);

end