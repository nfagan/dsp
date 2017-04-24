function obj = dsp__std_threshold( obj, n_devs )

assert( ndims(obj.data) == 2, ['Take a mean within time and frequency' ...
  , ' before thresholding'] );

stds = std( obj.data );
means = mean( obj.data );

greater_than = obj.data > means+stds*n_devs;
less_than = obj.data < means-stds*n_devs;

greater_than = any( greater_than, 2 );
less_than = any( less_than, 2 );

within_bounds = ~greater_than & ~less_than;

obj = obj.keep( within_bounds );

end