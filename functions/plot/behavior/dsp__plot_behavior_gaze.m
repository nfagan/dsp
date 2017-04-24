function dsp__plot_behavior_gaze( behav, trial_fields, save_path )

%   DSP__PLOT_BEHAVIOR_GAZE -- Plot gaze counts and quantities.
%
%     IN:
%       - `behav` (Container) -- Trial data as loaded by DSP_IO();
%       - `trial_fields` (cell array of strings) -- Cell array of strings
%         that identify each column in `behav`.
%       - `save_path` (char) -- Full path to the directory to save.

pl = ContainerPlotter();

looks = dsp__get_combined_looking_measures( behav, trial_fields );

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.save_outer_folder = save_path;

pl.plot_and_save( looks, 'look_type', @plot_by ...
  , 'outcomes' ...
  , 'looks_to' ...
  , {'trialtypes', 'look_type', 'look_period'} );


end