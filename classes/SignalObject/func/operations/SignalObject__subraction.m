function obj = SignalObject__subraction(a,b)

if ~isa(b,'SignalObject')
    error('The subtractor must be a signal object.');
end

if count(a,1) ~= count(b,1)
    error('Dimensions don''t match between signal objects');
end

if ~strcmp(a.dtype,b.dtype)
    error('Cannot mix and match windowed and non-windowed signals');
end

%{
    Method for windowed signals
%}

a_data = a.data;
b_data = b.data;

if strcmp(a.dtype,'cell')
    
    normalized = cell(size(a_data));
    
    for i = 1:size(a_data,1);
        for k = 1:size(a_data,2);
            normalized{i,k} = a_data{i,k} - b_data{i,k};
        end
    end
end

if strcmp(a.dtype,'double')
    
    normalized = a_data - b_data;
end

obj = a;
obj.data = normalized;

end