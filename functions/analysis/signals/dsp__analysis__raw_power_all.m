function signals = dsp__analysis__raw_power_all( signals, varargin )

[pow, f] = raw_power( signals, varargin{:} );
pow = SignalContainer.get_trial_by_time_double( pow );
signals.data = pow;
signals = update_frequencies( signals, f(:, 1) );

end