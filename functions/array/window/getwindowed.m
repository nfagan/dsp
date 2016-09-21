function obj = getwindowed(obj,step,w_size)

assert(isa(obj,'DataArrayObject'),'Input must be a DataArrayObject');

points = obj.DataPoints;

for i = 1:numel(points)
    points{i} = getwindowed(points{i},step,w_size);
end

obj = DataArrayObject(points{:});

end