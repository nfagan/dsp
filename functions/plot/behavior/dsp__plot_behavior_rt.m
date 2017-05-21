function dsp__plot_behavior_rt( behav, trial_fields, save_path )

%   DSP__PLOT_BEHAVIOR_RT -- Plot reaction time.
%
%     IN:
%       - `behav` (Container) -- Trial data as loaded by DSP_IO();
%       - `trial_fields` (cell array of strings) -- Cell array of strings
%         that identify each column in `behav`.
%       - `save_path` (char) -- Full path to the directory to save.

rt = dsp__get_rt( behav, trial_fields );

pl = ContainerPlotter();

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.bar( rt, 'outcomes', [], {'administration', 'trialtypes', 'monkeys', 'drugs'} );

full_save_path = fullfile( save_path, 'reaction_time' );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );

end