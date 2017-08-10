function dsp__plot_behavior_gaze_frequency( behav, trial_fields, save_path )

%   DSP__PLOT_BEHAVIOR_GAZE_FREQUENCY -- Plot gaze frequency
%
%     IN:
%       - `behav` (Container) -- Trial data as loaded by DSP_IO();
%       - `trial_fields` (cell array of strings) -- Cell array of strings
%         that identify each column in `behav`.
%       - `save_path` (char) -- Full path to the directory to save.

looks = dsp__get_combined_looking_measures( behav, trial_fields );
gazes = dsp__get_gaze_frequency( looks, ...
  {'days', 'outcomes', 'trialtypes', 'looks_to', 'look_period'} );

pl = ContainerPlotter();

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.plot_by( gazes, 'outcomes', 'looks_to' ...
  , {'administration', 'trialtypes', 'look_period', 'monkeys', 'drugs'} );

full_save_path = fullfile( save_path, 'social_gaze_frequency' );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );


end