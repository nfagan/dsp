function zscores = analysis__z_transformed_norm_power(obj, real_power)

validate_inputs(obj);

if ( nargin < 2 )    
    real_power = calc_power( obj );
end

repetitions = 10;

for i = 1:repetitions

permuted = permute( obj );
permuted = calc_power( permuted );

if ( i == 1 ); shuffled_power = permuted; continue; end;

shuffled_power = shuffled_power.append( permuted );

end

within = real_power.fieldnames();
[indices, combs] = getindices( real_power, within );

zscores = DataObject();

for i = 1:numel(indices)
    extr_real = real_power(indices{i});
    extr_shuffled = shuffled_power.only( combs(i,:) );
    
    extr_z = get_z_score( extr_real, extr_shuffled );
    
    zscores = zscores.append( extr_z );
end


end

function power = calc_power(obj)

power = analysis__norm_power( obj.toNormalize, obj.baseline, ...
    'method', 'multitaper', 'subtractReference', false );
power = power.subtract_across( ...
    'selfAndBoth', 'otherAndNone', 'receievedMinusForgone' );
power = SignalObject__mean_across( power, 'days' );


end

function distribution = get_distribution( shuffled, k )

data = shuffled.data;

distribution = zeros( numel(data), 1 );

for i = 1:numel(data)
    distribution(i) = data{i}(k);
end

distribution = fitdist( distribution, 'normal' );

end

function zscores = get_z_score( real, shuffled )

real_data = real.data{1};

z_scores = zeros( size(real_data) );

for i = 1:numel(real_data)
    disp(i);
    distribution = get_distribution( shuffled, i );
    
    test_val = real_data(i);
    
    z_scores(i) = abs( (test_val - distribution.mu) / distribution.sigma );
end

zscores = real;
zscores.data = {z_scores};


end


function permuted = permute(obj)

days = unique( obj.toNormalize('days') );

for i = 1:numel(days)
    ind = obj.toNormalize.where( days{i} );
    extr = obj.index(ind);
    
    shuffled_index = extr.toNormalize.randperm();
    
    extr = extr.shufflelabels('outcomes', shuffled_index);
    
    if ( i == 1 )
        store.toNormalize = extr.toNormalize; 
        store.baseline = extr.baseline;
        continue;
    end
    
    store.toNormalize = store.toNormalize.append( extr.toNormalize );
    store.baseline = store.baseline.append( extr.baseline );    
    
end

permuted = DataObjectStruct(store);

end


function validate_inputs(obj)

assert( isa(obj, 'DataObjectStruct'), '<obj> must be a DataObjectStruct' );
assert( all([ any(strcmp(obj.objectfields(), 'toNormalize')), ...
    any(strcmp(obj.objectfields(), 'baseline')) ]), ...
    '<obj> must be a DataObjectStruct with ''baseline'' and ''toNormalize'' fields');

end

% 
% for i = 1:numel(indices)
%     extr_real = real_power(indices{i});
%     extr_shuffled = shuffled_power.only( combs(i,exclude_days) );
%     
%     extr_z = get_z_score(extr_real, extr_shuffled);
%    
%     if ( i == 1 ); zscores = extr_z; continue; end;
%     
%     zscores = zscores.append( extr_z );
% end
% 
% 
% 
% %{
%     for each day (site) in real_power, shuffle the outcome labels
% %}
% 
% days = unique(real_power('days'));
% 
% shuffled_power = real_power;
% for i = 1:numel(days)
%     ind = real_power.where( days{i} );
%     extr = real_power(ind);
%     
%     shuffled_power(ind) = extr.shufflelabels('outcomes');
% end
% 
% combined = DataObjectStruct( struct( 'real', real_power, 'shuffled', shuffled_power ) );
% combined = combined.subtract_across( 'selfAndBoth', 'otherAndNone', 'receievedMinusForgone' );
% 
% real_power = combined.real;
% shuffled_power = combined.shuffled;
% 
% within = real_power.fieldnames();
% exclude_days = ~strcmp(within, 'days');
% 
% [indices, combs] = getindices( real_power, within );
% 
% for i = 1:numel(indices)
%     extr_real = real_power(indices{i});
%     extr_shuffled = shuffled_power.only( combs(i,exclude_days) );
%     
%     extr_z = get_z_score(extr_real, extr_shuffled);
%    
%     if ( i == 1 ); zscores = extr_z; continue; end;
%     
%     zscores = zscores.append( extr_z );
% end
% 
% zscores = SignalObject__mean_across( zscores, 'days' );


% 
% 
% function zscores = get_z_score_old(real, shuffled)
% 
% real_data = real.data{1};
% 
% zscores = zeros( size(real_data) );
% 
% for k = 1:numel(real_data)
%     disp(k);
%     
%     distribution = get_distribution( shuffled, k );
%     distribution = fitdist( distribution, 'normal' );
%     
%     test_val = real_data(k);
%     
%     zscores(k) = abs( (test_val - distribution.mu) / distribution.sigma );
% end
% 
% %   because the data labels and dimensions remain the same, simply replace the
% %   non-z-transformed data with the calculated z scores, and return
% 
% real.data = {zscores}; zscores = real;
% 
% end
% 
% %{
%     get a vector of data points of length <days> for each time-frequency
%     cell (i)
% %}
% 
% function distribution = get_distribution_old(shuffled, i)
% 
% data = shuffled.data;
% 
% distribution = zeros( numel(data), 1 );
% 
% for k = 1:numel(data)
%     distribution(k) = data{k}(i);
% end
% 
% end
