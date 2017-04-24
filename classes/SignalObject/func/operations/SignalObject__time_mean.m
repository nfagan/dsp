function obj = SignalObject__time_mean(obj, time, varargin)

assert( isa(time, 'double'), '<time> must be a two-element vector' );
assert( numel(time) == 2, '<time> must be a two-element vector' );
assert( time(1) < time(2), 'The second element of time must be > than the first' );
assert( strcmp(obj.dtype, 'cell'), 'The signals must be windowed' );

data = obj.data;

time_index = obj.time >= time(1) & obj.time <= time(2);

for i = 1:numel(data)
    extr = data{i}(:,time_index);
    extr = mean( extr, 2 );
    
    data{i} = extr;
end

obj.data = data;
obj.time = obj.time( time_index );

end