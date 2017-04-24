function [measures, behav, trial_fields] = dsp__get_column_behavior_measures( wanted_fields )

if ( ~iscell(wanted_fields) ), wanted_fields = { wanted_fields }; end;
assert( iscellstr(wanted_fields), ['Expected ''wanted_fields'' to be a ' ...
  , ' cell array of strings; was a ''%s'''], class(wanted_fields) );

io = DSP_IO();

behav_path = pathfor( 'BEHAVIOR' );
load( fullfile(behav_path, 'trial_fields.mat') );
behav = io.load( behav_path );

matches = cellfun( @(x) find(strcmp(trial_fields, x)), wanted_fields, 'un', false );
any_are_empty = any( cellfun(@isempty, matches) );
assert( ~any_are_empty, 'At least one of the specified fields does not exist.' );

matches = [ matches{:} ];

measures = Structure();
for i = 1:numel(matches)
  field = wanted_fields{i};
  column = matches(i);
  extr = behav;
  extr.data = extr.data(:, column);
  measures.(field) = extr;
end

end