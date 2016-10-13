%{
    reject trials in which any signals are above this threshold
%}

function fixed = SignalObject__exclude(objs,limits)

%{
    validation
%}

if isa(objs,'SignalObject')
    objs = {objs};
end

msg1 = 'If specifying more than one object, the objs must be grouped in a cell array';
msg2 = 'All elements must be SignalObjects';
msg3 = 'The number of trials isn''t consistent between objects';
msg4 = 'Limits must be a two-element vector';
msg5 = 'The first element of limits must be less than the second';

assert(iscell(objs),msg1);
assert(all(cellfun(@(x) isa(x,'SignalObject'),objs)),msg2);

assert(all(cellfun(@(x) strcmp(x.dtype,'double'),objs)),'dtype must be double');

first_n_trials = count(objs{1},1);

if length(objs) > 1
    assert(all(cellfun(@(x) count(x,1) == first_n_trials,objs(2:end))),msg3);
end

assert(isa(limits,'double') & length(limits) == 2,msg4);
assert(limits(1) < limits(2),msg5);

%{
    index
%}

index = true(count(objs{1},1),1);

for i = 1:numel(objs)
    signals = objs{i}.data;
    index = index & get_index_within_limits(signals,limits);
end

fixed = cell(size(objs));

for i = 1:numel(objs)
    fixed{i} = objs{i}(index);
end

fprintf('\nExcluded %f percent\n',perc(~index));

end

function index = get_index_within_limits(signals,limits)

    out_of_bounds = signals < limits(1) | signals > limits(2);
    index = sum(out_of_bounds,2) == 0;

end





function data = cell_data(signals,limits)

ind = false(size(signals{1}));

for i = 1:numel(signals)
    out_of_bounds = signals{i} < limits(1) | signals{i} > limits(2);
    ind = ind | out_of_bounds;
end

ind = sum(ind,2) == 0; 

data = signals(ind,:);

end
