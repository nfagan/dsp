function z_transformed = dsp__z_transform( distr )

assert( isa(distr, 'Structure'), ['The real and shuffled distributions' ...
  , ' must be a Structure (i.e., the output of dsp__get_distributions);' ...
  , ' values were a ''%s''.'], class(distr) );
assert( all(distr.are_fields( {'real', 'shuffled'})), ['The structure must have' ...
  , ' ''real'' and ''shuffled'' fields.'] );
assert( isa(distr{1}.labels, 'SparseLabels'), 'Labels must be SparseLabels.' );

distr = distr.update_label_sparsity();
non_uniform = setdiff( distr.real.field_names(), distr.real.get_uniform_categories() );
if ( ~isempty(non_uniform) )
  objs = distr.enumerate( non_uniform );
else
  fields = distr.real.field_names();
  objs = distr.enumerate( fields{1} );
end

z_transformed = Container();

for i = 1:numel(objs{1})
  fprintf( '\n Processing %d of %d', i, numel(objs{1}) );
  real = objs.real{i};
  shuffled = objs.shuffled{i};
  zs = zeros( size(real.data) );
  for k = 1:size( real.data, 3 )
    real_one_time = real.data(:, :, k);
    shuff_one_time = shuffled.data(:, :, k);
    one_time_z = zeros( size(real_one_time) );
    for j = 1:numel(real_one_time)
      dist = fitdist( shuff_one_time(:, j), 'normal' );
      test_val = real_one_time(j);
      one_time_z(j) = (test_val - dist.mu) / dist.sigma;
    end
    zs(:, :, k) = one_time_z;
  end
  real.data = zs;
  z_transformed = z_transformed.append( real );
end

end