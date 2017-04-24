function obj = dsp__percent_in_range( obj, values )

assert( isa(obj, 'SignalContainer'), ['Object must be a SignalContainer;' ...
  , ' was a ''%s'''], class(obj) );
assert( isfield(obj.trial_stats, 'percent_per_day'), ['Run this after' ...
  , ' adding percent_per_day'] );
percent = obj.trial_stats.percent_per_day;
ind = percent >= values(1) & percent <= values(2);
obj = obj.keep( ind );

end