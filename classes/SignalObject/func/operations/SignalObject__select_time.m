function obj = SignalObject__select_time(obj, time)

data = obj.data;

time_ind = obj.time >= time(1) & obj.time <= time(2);

data = cellfun( @(x) x(:,time_ind), data, 'UniformOutput', false );

obj.time = time;
obj.data = data;


end