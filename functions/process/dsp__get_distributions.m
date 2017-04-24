function distr = dsp__get_distributions( real, shuffled_labels, within )

%   determine which trials fall within voltage and std deviation thresholds

within_voltage_range = real.trial_stats.range <= .3;
meaned = real.keep( within_voltage_range );
meaned = meaned.time_freq_mean( [], [0 100] );
within_std_threshold = dsp__std_threshold_index( meaned ...
  , {'regions', 'monkeys', 'drugs', 'outcomes'}, 2 );

%   now, when we reorder the data for each shuffled_labels, we can still
%   keep only the good trials based on the real data.

real.trial_stats.good_trials = false( shape(real, 1), 1 );
real.trial_stats.good_trials( within_voltage_range ) = within_std_threshold;

iterations = unique( shuffled_labels('iterations') );

distr = Structure( 'shuffled', Container() );

for i = 1:numel(iterations)
  fprintf( '\n Iteration %d of %d', i, numel(iterations) );
  one_iter = shuffled_labels.only( iterations{i} );
  assert( one_iter.shape(1) == real.shape(1), ['The shapes of the shuffled labels' ...
    , ' and real data do not match.'] );
  real_shuffled = real.reorder_data( one_iter.data );
  real_shuffled.labels = one_iter.labels.rm_fields( 'iterations' );
  
  good_trials = real_shuffled.trial_stats.good_trials;
  real_shuffled = real_shuffled.keep( good_trials );
  
  shuffled_meaned = real_shuffled.mean_within( within );
  distr.shuffled = distr.shuffled.append( shuffled_meaned );
end

real = real.keep( real.trial_stats.good_trials );
real = real.mean_within( within );
distr.real = real;

missing = get_missing_combs( real, within );
if ( isempty(missing) ), return; end;

for i = 1:size( missing, 1 )
  ind = distr.shuffled.where( missing(i, :) );
  if ( ~any(ind) ), continue; end;
  distr.shuffled = distr.shuffled.keep( ~ind );
end

end

function missing_combs = get_missing_combs( real, within )

c = real.combs( within );
were_missing = false( size(c, 1), 1 );

for i = 1:size( c, 1 )
  ind = real.where( c(i, :) );
  if ( any(ind) ), continue; end;
  were_missing(i) = true;
end

missing_combs = c( were_missing, : );

end