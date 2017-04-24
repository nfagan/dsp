function [measure, N, all_trials, empties] = dsp__bound_trials_by_trial_names( measure, ids, bounded_ids )

data = measure.data;
assert( numel(data) == numel(ids), 'Mismatch between trial-identifiers and data' );

empties = false( count(measure,1), 1 );

N = zeros( numel(data), 1 );
all_trials = zeros( numel(data), 1 );

for i = 1:numel(data)
  fprintf( '\n Processing %d of %d', i, numel(data) );
  current_ids = ids{i};
  not_found = arrayfun( @(x) ~any(bounded_ids == x), current_ids );
  data{i} = cellfun( @(x) x(:, ~not_found), data{i}, 'un', false );
  if ( isempty(data{i}{1}) )
    empties(i) = true;
  end
  all_trials(i) = numel(not_found);
  N(i) = sum(not_found);
end

measure.data = data;
measure = measure( ~empties );

% N = sum(N) / sum(all_trials);

end