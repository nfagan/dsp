function [measure, n_excl, n_total, empties] = ...
  dsp__bound_measure( measure, measure_ids, signals, signal_ids, threshold, varargin )

params.selectors = [];
params = parsestruct( params, varargin );

if ( ~isempty(params.selectors) )
  selectors = params.selectors;
  error_msg = 'No elements matched the given selectors';
  signal_ind = signals.where( selectors );
  assert( any(signal_ind), error_msg );
  signals = signals( signal_ind );
  signal_ids = signal_ids( signal_ind );
  measure_ind = measure.where( selectors );
  assert( any(measure_ind), error_msg );
  measure = measure( measure_ind );
  measure_ids = measure_ids( measure_ind );
end

bounds = dsp__get_in_bounds_trial_names( signals, signal_ids, threshold );
[measure, n_excl, n_total, empties] = ...
  dsp__bound_trials_by_trial_names( measure, measure_ids, bounds );



end