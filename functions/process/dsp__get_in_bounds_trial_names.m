function names = dsp__get_in_bounds_trial_names( obj, ids, threshold )

data = obj.data;

mins = min( data, [], 2 );
maxs = max( data, [], 2 );
in_bounds = ( maxs - mins ) <= threshold;

names = unique( ids(in_bounds) );

end