function obj = point2signal(obj,fs,time)

assert(isa(obj,'DataArrayObject'),'Input must be a DataArrayObject');

points = obj.DataPoints;

for i = 1:numel(points)
   points{i} = SignalPoint(points{i}.data,points{i}.labels,fs,time);
end

obj = DataArrayObject(points{:});

end