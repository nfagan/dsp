function dsp__plot_behavior_rt( behav, trial_fields, save_path )

%   DSP__PLOT_BEHAVIOR_RT -- Plot reaction time.
%
%     IN:
%       - `behav` (Container) -- Trial data as loaded by DSP_IO();
%       - `trial_fields` (cell array of strings) -- Cell array of strings
%         that identify each column in `behav`.
%       - `save_path` (char) -- Full path to the directory to save.

ind = strcmp( trial_fields, 'reaction_time' );
assert( any(ind), 'Could not find a reaction_time column.' );

pl = ContainerPlotter();

rt = behav;
rt.data = rt.data(:, ind);
nans = any( isnan(rt.data), 2);
rt = rt.keep( ~nans );

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.bar( rt, 'outcomes', [], {'administration', 'trialtypes'} );

full_save_path = fullfile( save_path, 'reaction_time' );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );

end