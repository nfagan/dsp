function rt = dsp__get_rt( behav, trial_fields )

ind = strcmp( trial_fields, 'reaction_time' );
assert( any(ind), 'Could not find a reaction_time column.' );
rt = behav;
rt.data = rt.data(:, ind);
nans = any( isnan(rt.data), 2);
rt = rt.keep( ~nans );

end