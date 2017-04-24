function new_obj = dsp__get_measure_over_time( obj, n_bins )

start = 0;
stp = 1/n_bins;
new_obj = obj;
new_obj = new_obj.collapse_non_uniform();
new_obj = new_obj.keep_one(1);

assert( shape(obj, 2) == 1, ['Data in the object must be an Mx1 column vector;' ...
  , ' data had %d columns'], shape(obj, 2) );

for i = 1:n_bins
  in_bounds = dsp__percent_in_range( obj, [start, start+stp] );
  new_obj.data(i) = mean( in_bounds.data );
  start = start + stp;
end


end