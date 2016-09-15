function unwindowed = SignalObject__windowconcat(obj)

if ~strcmp(obj.dtype,'cell')
    error('Signals are not windowed');
end

signals = obj.data;

n_windows = size(signals,2);
unwindowed = cell(1,n_windows);

for i = 1:n_windows
    
unwindowed{i} = concat(signals(:,i));    
    
end


end

function matrix = concat(onewindow)

cols = size(onewindow{1},2);
rows = size(onewindow,1);

matrix = zeros(rows,cols);

for i = 1:length(onewindow)
    matrix(i,:) = onewindow{i};
end

end

