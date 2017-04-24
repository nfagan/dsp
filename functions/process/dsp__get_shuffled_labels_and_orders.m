function orders = dsp__get_shuffled_labels_and_orders( measure, within, n_reps, shuffle_field )

if ( nargin < 4 ), shuffle_field = 'outcomes'; end;

orders = Container();

for i = 1:n_reps
  fprintf( '\n Processing iteration %d of %d', i, n_reps );
  [shuffled, order] = shuffle_within( measure, within, shuffle_field );
  shuffled = shuffled.add_field( 'iterations', sprintf('iteration__%d', i) );
  orders = orders.append( Container(order, shuffled) );
end

end

function [new_labels, orders] = shuffle_within( obj, within, shuffle_field )

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
  shuffled = dsp__shuffle_labels( Container(data, labs), shuffle_field );  
  new_labels = new_labels.append( shuffled.labels );
end

end