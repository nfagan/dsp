function measure = dsp__get_measure_with_behavior(signal_measure_path, selectors, behav_measures, behav_measure_path)

if ( nargin < 4 ), behav_measure_path = 'H:\SIGNALS\behavior'; end
if ( nargin < 3 )
  behav_measures = {'reaction_time', 'earlyLookCount', 'earlyBottleLookCount'};
else
  if ( ~iscell(behav_measures) ), behav_measures = { behav_measures }; end;
end
if ( nargin < 2 ), selectors = []; end;

io = DSP_IO();

if ( isequal(selectors, []) )
  measure = io.load( signal_measure_path );
  behav = io.load( behav_measure_path );
else
  measure = io.load( signal_measure_path, 'only', selectors );
  behav = io.load( behav_measure_path, 'only', selectors );
end

measure = measure.update_label_sparsity();
load( fullfile(behav_measure_path, 'trial_fields') );

for i = 1:numel(behav_measures)
  col = find( strcmp(trial_fields, behav_measures{i}) );
  assert( ~isempty(col), 'Could not find the desired field ''%s''', behav_measures{i} );
  behav_measure = behav;
  behav_measure.data = behav_measure.data(:, col);
  measure = dsp__add_behavior_to_trial_stats( measure, behav_measure, behav_measures{i} );
end