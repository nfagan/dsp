function new_obj = dsp__behavior__preference_index_over_time( obj, n_bins, within, varargin )

start = 0;
stp = 1/n_bins;
new_obj = Container();
for i = 1:n_bins
  extr = dsp__percent_in_range( obj, [start, start+stp] );
  pref = dsp__behavior_preference_index_within( extr, within, varargin{:} );
  if ( isempty(pref) ), continue; end;
  pref.trial_stats.percent_per_day(:) = start;
  new_obj = new_obj.append( pref );
  start = start + stp;
end
end