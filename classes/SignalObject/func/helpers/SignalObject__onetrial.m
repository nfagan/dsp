function obj = SignalObject__onetrial(obj,n)

if nargin < 2
    n = 1;
end

assert(isa(obj,'DataObject'),'Input must be a DataObject');
assert(strcmp(obj.dtype,'cell'),'Input must be of dtype ''cell''');

data = obj.data;

assert(iscell(data{1}),'Data in the object must be a cell array of cells');

newarray = cell(size(data));

for i = 1:numel(data)
    matrix = zeros(size(data{1}{1},1),size(data{1},2));
    for k = 1:size(matrix,2)
        matrix(:,k) = data{i}{k}(:,n);
    end
    newarray{i} = matrix;
end

obj.data = newarray;

end