function signal = dsp__add_behavior_to_trial_stats( signal, behav, name )

if ( nargin < 3 ), name = 'behavior'; end;

assert( shape(behav, 2) == 1, 'Data in the behavior object must be a column vector' );

days = unique( signal('days') );
if ( signal.contains_categories('sites') )
  use = 'sites';
else use = 'channels';
end

behav_values = zeros( shape(signal, 1), 1 );

for i = 1:numel(days)
  extr_signal = signal.only( days{i} );
  extr_behav = behav.only( days{i} );
  secondary = unique( extr_signal(use) );
  for k = 1:numel(secondary)
    full_ind = signal.where( {days{i}, secondary{k}} );
    behav_values( full_ind ) = extr_behav.data;
  end
end

signal.trial_stats.(name) = behav_values;

end