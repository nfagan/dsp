function windowed = SignalObject__get_windowed_data(obj, step, w_size)

fs = obj.fs;
signals = obj.data; 

multiplier = fs / 1000;

w_size = w_size * multiplier;
step = step * multiplier;

max_n_windows = size(signals,2) / step;

stp = 0; windowed = cell(1,max_n_windows);

i = 1;
while i <= max_n_windows && (w_size + stp) <= size(signals,2)
    windowed{i} = signals(:,1+stp:w_size+stp);
    stp = stp + step;
    i = i + 1;
end
empty = cellfun('isempty',windowed);
windowed(empty) = [];

end