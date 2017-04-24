function full_ind = dsp__std_threshold_index( obj, within, n_devs )

assert( ndims(obj.data) == 2, ['Take a mean within time and frequency' ...
  , ' before thresholding'] );

inds = obj.get_indices( within );
full_ind = false( shape(obj,1), 1 );

for i = 1:numel(inds)
  current_ind = inds{i};
  extr = obj.keep( current_ind );
  stds = std( extr.data );
  means = mean( extr.data );
  greater_than = any( extr.data > means+stds*n_devs, 2 );
  less_than = any( extr.data < means-stds*n_devs, 2 );
  within_bounds = ~greater_than & ~less_than;
  current_ind(~within_bounds) = false;
  full_ind( current_ind ) = true;
end

end