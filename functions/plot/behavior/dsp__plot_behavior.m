function dsp__plot_behavior(behav, trial_fields, save_path)
%%  get preference index, per day

pref = dsp__behavior_preference_index_within( behav, {'days', 'trialtypes'} );

%%  get separate measures

desired_measures = { 'reaction_time' };

measures = struct();
for i = 1:numel( desired_measures )
  current = desired_measures{i};
  ind = strcmp( trial_fields, current );
  assert( sum(ind) == 1, 'No matches for ''%s''', current );
  current_measure = behav;
  current_measure.data = current_measure.data( :, ind );
  nans = any( isnan(current_measure.data), 2 );
  current_measure = current_measure.keep( ~nans );
  measures.( desired_measures{i} ) = current_measure;
end

measures.preference_index = pref;

%%  get looking measures

looks = dsp__get_combined_looking_measures( behav, trial_fields );

%%  plot

pl = ContainerPlotter();

%%  plot reaction time

current_name = 'reaction_time';

rt = measures.(current_name);

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.bar( rt, 'outcomes', [], {'administration', 'trialtypes'} );

full_save_path = fullfile( save_path, current_name );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );

%%  plot 'social gaze' counts + quantities

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.save_outer_folder = save_path;

pl.plot_and_save( looks, 'look_type', @plot_by ...
  , 'outcomes' ...
  , 'looks_to' ...
  , {'trialtypes', 'look_type', 'look_period'} );

%%  plot gaze frequency

current_name = 'social_gaze_frequency';

gazes = looks.only( 'count' );
%   make into frequency
gazes.data = double( gazes.data > 0 );
%   get number of trials within 'days', etc.
Ns = gazes.counts( {'days', 'outcomes', 'trialtypes', 'looks_to', 'look_period'} );
%   get sum of binary look counts within 'days', etc.
freqs = gazes.do( {'days', 'outcomes', 'trialtypes', 'looks_to', 'look_period'}, @sum );
%   divide within 'days', etc.
gazes = freqs ./ Ns;
gazes.data = gazes.data * 100;

figure;
pl.default();
pl.order_by = { 'self', 'both', 'other', 'none' };
pl.plot_by( gazes, 'outcomes', 'looks_to', {'administration', 'trialtypes', 'look_period'} );

full_save_path = fullfile( save_path, current_name );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );


%%  plot preference index

current_name = 'preference_index';

pref = measures.(current_name);

figure;
pl.default();
pl.order_by = { 'other:none', 'self:both' };
pl.bar( pref, 'outcomes', 'trialtypes', {'administration', 'trialtypes'} );

full_save_path = fullfile( save_path, current_name );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );

end
