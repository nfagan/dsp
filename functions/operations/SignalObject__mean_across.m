function store = SignalObject__mean_across(obj, across)

within = obj.label_fields;

within = within( ~strcmp(within, across) );

indices = obj.getindices( within );

for i = 1:numel(indices)
    
    per = obj( indices{i} );
    
    per(across) = ['all_' across];
    
    labels = per(1).labels;
    data = per.data;
    
    matrix = zeros( size(data{1}) );
    
    for j = 1:numel(data{1})
        one_freq = zeros( 1, size(data,1) );
        for k = 1:size(data, 1)
            one_freq(k) = data{k}(j);
        end
        one_freq = mean(one_freq);
        matrix(j) = one_freq;
    end
    
    if ( i == 1 )
        store = SignalObject( DataObject({matrix}, labels), obj.fs, obj.time ); 
        continue;
    end
    
    store = [store; SignalObject( DataObject({matrix}, labels), obj.fs, obj.time ) ];
    
end