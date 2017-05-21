function dsp__plot_behavior_pref_index( behav, save_path )

%   DSP__PLOT_BEHAVIOR_PREF_INDEX -- Plot preference index.
%
%     IN:
%       - `behav` (Container) -- Trial data as loaded by DSP_IO();
%       - `save_path` (char) -- Full path to the directory to save.

pref = dsp__behavior_preference_index_within( behav, {'days', 'trialtypes'} );

pl = ContainerPlotter();

figure;
pl.default();
pl.order_by = { 'other:none', 'self:both' };
pl.bar( pref, 'outcomes', 'trialtypes', {'administration', 'trialtypes', 'monkeys', 'drugs'} );
pl.save_outer_folder = save_path;
% pl.plot_and_save( pref ...
%   , {'administration', 'trialtypes', 'monkeys', 'drugs'} ...
%   , @bar ...
%   , 'outcomes' ...
%   , 'trialtypes' ...
%   , 'monkeys' ...
% );

full_save_path = fullfile( save_path, 'preference_index' );
saveas( gcf, [full_save_path, '.eps'], 'epsc' );
saveas( gcf, [full_save_path, '.png'], 'png' );


end