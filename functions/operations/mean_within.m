function mean_across(obj, across)

n_power = obj

within = n_power.label_fields;

within = within( ~strcmp(within, 'days') );

indices = n_power.getindices( within );

for i = 1:numel(indices)
    
    perday = n_power( indices{i} );
    
    perday('days') = 'all_days';
    
    labels = perday(1).labels;
    data = perday.data;
    
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
        store = SignalObject( DataObject({matrix}, labels), n_power.fs, n_power.time ); 
        continue;
    end
    
    store = [store; SignalObject( DataObject({matrix}, labels), n_power.fs, n_power.time ) ];
    
end