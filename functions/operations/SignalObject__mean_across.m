function [store, store_errors] = SignalObject__mean_across(obj, across, replacewith)

within = obj.fieldnames( '-except', across );

indices = obj.getindices( within );

store = DataObject();
store_errors = DataObject();

for i = 1:numel(indices)    
    per = obj( indices{i} );
    
    per = per.collapse(across);
    
    tostore = per(1);
    
    data = per.data;
    
    matrix = zeros( size(data{1}) );
    
    errors = zeros( size(data{1}) );
    
    for j = 1:numel(data{1})
        one_freq = zeros( 1, size(data,1) );
        for k = 1:size(data, 1)
            one_freq(k) = data{k}(j);
        end
        one_freq_errors = SEM(one_freq);
        one_freq = mean(one_freq);
        matrix(j) = one_freq;
        errors(j) = one_freq_errors;
    end
    
    %   save means and errors
    
    tostore.data = {matrix};

    store = store.append( tostore );    
    
    tostore.data = {errors};
    
    store_errors = store_errors.append( tostore );
end

if ( nargin < 3 ); return; end;

store = store.setfield( across, replacewith );

end