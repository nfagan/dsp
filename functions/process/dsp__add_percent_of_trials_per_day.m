function new_obj = dsp__add_percent_of_trials_per_day( obj )

days = unique( obj('days') );
new_obj = Container();
for i = 1:numel(days)
  extr = obj.only( days{i} );
  n_trials = shape( extr, 1 );
  percent = ( 1:n_trials ) / n_trials;
  extr.trial_stats.percent_per_day = percent(:);
  new_obj = new_obj.append( extr );
end

end