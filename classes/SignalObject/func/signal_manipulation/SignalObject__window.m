function obj = SignalObject__window(obj,step,w_size)

binned = windowed_data( obj, step, w_size );

formatted = cell(size(binned{1},1),size(binned,2));
for i = 1:size(binned{1},1);
    for k = 1:size(binned,2)
        formatted(i,k) = {binned{k}(i,:)};
    end
end

obj.data = formatted;
obj = SignalObject(obj,obj.fs,obj.time);

end

% fs = obj.fs;
% signals = obj.data; 
% 
% multiplier = fs / 1000;
% 
% w_size = w_size * multiplier;
% step = step * multiplier;
% 
% max_n_windows = size(signals,2) / step;
% 
% stp = 0; binned = cell(1,max_n_windows);
% 
% i = 1;
% while i <= max_n_windows && (w_size + stp) <= size(signals,2)
%     binned{i} = signals(:,1+stp:w_size+stp);
%     stp = stp + step;
%     i = i + 1;
% end
% empty = cellfun('isempty',binned);
% binned(empty) = [];