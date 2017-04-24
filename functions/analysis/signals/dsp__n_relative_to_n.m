function measure = dsp__n_relative_to_n(obj, ns)

objs = enumerate( obj, {'sites', 'days'} );

ns = unique( ns );

current = nan( shape(obj) );
prev = cell( 1, numel(ns) );
prev = cellfun( @(x) nan(shape(obj)), prev, 'un', false );
previous_labels = cell( 1, numel(ns) );
previous_labels = cellfun( @(x) SparseLabels(), previous_labels, 'un', false );
current_labels = SparseLabels();

colons = repmat( {':'}, 1, ndims(obj.data)-1 );

stp = 1;

for i = 1:numel(objs)
  fprintf( '\n %d of %d', i, numel(objs) );
  extr = objs{i};
  trial_ids = extr.trial_ids;
  for k = 1:numel(trial_ids)
    curr_id = trial_ids(k);
    exists = all( arrayfun( @(x) any(trial_ids == curr_id+x), ns ) );
    if ( ~exists ), continue; end;
    current_ind = extr.trial_ids == curr_id;
    inds = arrayfun( @(x) trial_ids == curr_id+x, ns, 'un', false );
    for j = 1:numel(ns)
      prev{j}(stp, colons{:}) = extr.data( inds{j}, colons{:} );
      previous_labels{j} = previous_labels{j}.append( extr(inds{j}).labels );
    end
    current(stp, colons{:}) = extr.data( current_ind, colons{:} );
    current_labels = current_labels.append( extr(current_ind).labels );
    stp = stp + 1;
  end
end

current( stp:end, colons{:} ) = [];
for j = 1:numel(ns)
  prev{j}( stp:end, colons{:} ) = [];
end

current_cont = Container( current, current_labels );
current_cont = current_cont.add_field( 'trialset', 'n' );
previous_container = Container();
for i = 1:numel(ns)
  prev_cont = Container( prev{j}, previous_labels{j} );
  prev_cont = prev_cont.add_field( 'trialset', ['n_' num2str(ns(i))] );
  previous_container = previous_container.append( prev_cont );
end

measure = current_cont.append( previous_container );

end