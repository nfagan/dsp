function to_norm = dsp__analysis__norm_power_all( to_norm, norm_by, varargin )

[pow, f] = norm_power( to_norm, norm_by, varargin{:} );
pow = SignalContainer.get_trial_by_time_double( pow );
to_norm.data = pow;
to_norm = update_frequencies( to_norm, f(:, 1) );
to_norm.trial_stats.range = ...
  max( [to_norm.trial_stats.range, norm_by.trial_stats.range], [], 2 );

end