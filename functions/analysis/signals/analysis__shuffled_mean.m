function store = analysis__shuffled_mean(obj)

within = obj.fieldnames();
indices = obj.getindices( within );

store = DataObject();

for i = 1:numel(indices)
    
    extr = obj(indices{i});
    data = get_mean( extr.data );
    
    extr = extr(1); extr.data = {data};
    
    store = store.append( extr );
end

end

function matrix = get_mean( data )

matrix = zeros( size(data{1}) );

for i = 1:numel(data{1})
    across_shuffles = zeros( 1, numel(data) );
    for j = 1:numel(data)
        across_shuffles(j) = data{j}(i);
    end
    matrix(i) = mean( across_shuffles );
end



end