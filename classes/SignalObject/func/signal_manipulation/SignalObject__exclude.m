%{
    reject trials in which any signals are above this threshold
%}

function fixed = SignalObject__exclude(obj,limits)

signals = obj.data;

assert(numel(limits) == 2,'Limits must have two elements');

switch signals.dtype
    case 'cell'
        fixed = cellfun(@(x) cell_data(x,limits), signals, 'UniformOutput',false);
    case 'double'
        fixed = cellfun(@(x) double_data(x,limits), signals, 'UniformOuput',false);
end
    
end

function data = double_data(signals,limits)

ind = signals < limits(1) | signals > limits(2);

ind = sum(ind,2) == 0;

data = signals(ind,:);

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
