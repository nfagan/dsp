function distr = dsp__get_shuffled_distribution( measure, mean_within, n_reps )

distr = Container();

for i = 1:n_reps
  fprintf( '\n Processing iteration %d of %d', i, n_reps );
  shuffled = shuffle_within( measure, {'days', 'sites', 'trialtypes', 'administration'} );
  shuffled = shuffled.mean_within( mean_within );
  distr = distr.append( shuffled );
end

end

function obj = shuffle_within( obj, within )

inds = obj.labels.get_indices( within );
orders = zeros( obj.shape(1), 1 );
start = 1;

new_labels = SparseLabels();

for i = 1:numel(inds)
  current_n = sum( inds{i} );
  orders( start:start+current_n-1 ) = find( inds{i} );
  start = start + current_n;
  data = zeros( current_n, 1 );
  labs = obj.labels.keep( inds{i} );
  shuffled = dsp__shuffle_labels( Container(data, labs), 'outcomes' );  
  new_labels = new_labels.append( shuffled.labels );
end

colons = repmat( {':'}, 1, ndims(obj.data) );
new_data = obj.data( orders, colons{:} );

obj.data = new_data;
obj.labels = new_labels;

end