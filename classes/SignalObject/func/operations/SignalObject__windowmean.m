function obj = SignalObject__windowmean(obj,dim)

if nargin < 2
    dim = 2;    %   NOTE: this isn't default behavior. But because power / 
                %   coherence is stored columnwise, we *usually* want to
                %   average across columns
end

assert(strcmp(obj.dtype,'cell'),'Signals are not windowed');

data = obj.data;

for i = 1:numel(data)
    averaged = cellfun(@(x) mean(x,dim), data{i}, 'UniformOutput', false);
    
    matrix = zeros(size(averaged{1},1),size(averaged,2));
    
    for k = 1:numel(averaged)
        matrix(:,k) = averaged{k};
    end
    
    data{i} = matrix;
end

obj.data = data;

end