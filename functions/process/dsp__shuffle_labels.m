function obj = dsp__shuffle_labels( obj, category )

assert( isa(category, 'char'), 'Expected category to be a char; was a ''%s''.' ...
  , class(category) );

if ( isa(obj.labels, 'SparseLabels') )
  [inds, combs] = obj.get_indices( category );
  inds = cellfun( @(x) full(x), inds, 'un', false );
  nums = cellfun( @(x) sum(x), inds );
  sample_vector = 1:obj.shape( 1 );
  for i = 1:numel(nums)
    numeric_inds = datasample( sample_vector, nums(i), 'replace', false );
    sample_vector = setdiff( sample_vector, numeric_inds );
    inds{i}(:) = false;
    inds{i}(numeric_inds) = true;
  end
  inds = cellfun( @(x) sparse(x), inds', 'un', false );
  inds = [ inds{:} ];
  inds_in_labels = cellfun( @(x) find(strcmp(obj.labels.labels, x)), combs(:)' );
  obj.labels.indices(:, inds_in_labels) = inds;
  return
end

labs = obj( category );
new_order = randperm( shape(obj, 1) );
shuffled = labs( new_order(:) );
ind_in_fields = strcmp( obj.labels.fields, category );
obj.labels.labels(:, ind_in_fields) = shuffled;

end