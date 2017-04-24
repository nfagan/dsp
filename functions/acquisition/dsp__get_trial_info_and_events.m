function info_events = dsp__get_trial_info_and_events(db, SESSIONS)

assert( isa(db, 'DictatorSignalsDB'), ['Expected input to be a DictatorSignalsDB' ...
  , ' object; was a ''%s'''], class(db) );

%   PARAMETERS

DATA_FIELDS.signals = 'file';
DATA_FIELDS.align = { 'plex', 'picto' };
DATA_FIELDS.events = { 'fixOn', 'cueOn', 'targOn', 'targAcq', 'rwdOn' };
DATA_FIELDS.meta = { 'session', 'actor', 'recipient', 'drug' };

%   use all sessions in the database by default; this can be changed to a)
%   a cell array of session names, or b) a path to a subfolder housing the
%   desired sessions -- in this case, call get_folder_names( subfolder ) to
%   get the names of the sessions within. Only works if the session names
%   are the names of the folders.

if ( nargin < 2 )
  SESSIONS = unique( db.get_fields('session', 'signals') );
end

%   END PARAMETERS

if ( isempty(SESSIONS) || isequal(SESSIONS{1}, 'No Data') )
  error( 'Database ''%s'' was empty', db.filename );
end

info_events = Container();

for i = 1:numel(SESSIONS)
  session = sprintf( '"%s"', SESSIONS{i} );
  fprintf( '\n - Processing Session %s (%d of %d)', session, i, numel(SESSIONS) );
  
  align =       db.get_fields_where_session( DATA_FIELDS.align, 'align', session );
  trial_info =  db.get_fields_where_session( '*', 'trial_info', session );
  events =      db.get_fields_where_session( DATA_FIELDS.events, 'events', session );
  meta =        db.get_fields_where_session( DATA_FIELDS.meta, 'meta', session );
  file =        db.get_fields_where_session( 'file', 'signals', session );
  
  %   reformat
  
  events = cell2mat( events );
  align = cell2mat( align );
  file = unique( file );
  assert( numel(file) == 1, 'Too many files' );
  file = get_filename( file{1}, false );
  
  %   validate
  
  assert( size(trial_info,1) == size(events,1), ['Mismatch in number of rows' ...
    , ' between events and trial_info. You may wish to regenerate the database'] );
  
  %   alignment
  
  cued = events(:, 4) == 0 & events(:, 1) ~= 0;
  no_rwd = events(:, 5) == 0;
  events = adjusted_event_times( events, align );
  events( cued, 4 ) = 0;
  events( no_rwd, 5 ) = 0;  
  
  labels = build_labels( db, trial_info, meta, DATA_FIELDS.meta, file ); 
  
  info_events = info_events.append( Container(events, labels) );
end

info_events = dsp__post_process( info_events );

end

function str = get_filename( filename, keep_extension )

if ( ispc )
  search_char = '\';
else search_char = '/';
end

last = max( strfind(filename, search_char) );
str = filename( last+1:end );

if ( keep_extension ), return; end;

period_ind = strfind( str, '.' );
if ( isempty(period_ind) ), return; end;
str = str( 1:period_ind-1 );

end

function events = adjusted_event_times( events, align )

%   ADJUSTED_EVENT_TIMES -- Express the picto event times in terms of
%     Plexon time.
%     
%     IN:
%       - `events` (matrix) -- Event times; expected to have at least 2
%         columns. Rows where the first column is 0 are assumed to be error
%         trials, and are not aligned.
%       - `align` (matrix) -- Strobed align times between Picto and Plexon.
%         The first column is assumed to be Plex times; the second Picto
%         times.
%     OUT:
%       - `events` (matrix) -- Aligned event times.

plex = align(:, 1);
picto = align(:, 2);
non_zeros = events(:, 1) ~= 0;
to_align = events( non_zeros, : );
try
  closest_inds = arrayfun( @(x) find(picto < x, 1, 'last'), to_align(:,1) );
catch
  error( 'The align file does not match the given events' );
end

offset = to_align(:,1) - picto(closest_inds);
start = plex(closest_inds) + offset;
aligned = to_align;
aligned(:, 1) = start;
for i = 1:size(aligned, 2)
  aligned(:, i) = to_align(:, i) - to_align(:, 1) + start;
end
events( non_zeros, : ) = aligned;

end

function labels = build_labels( db, trial_info, meta, meta_fields, filename  )

trial_tbl_fields = db.get_field_names( 'trial_info' );

desired_trial_cols = { 'trialType', 'magnitude', 'cueType', 'fix', 'folder', 'trial' };

for i = 1:numel(desired_trial_cols)
  col_ind = strcmp( trial_tbl_fields, desired_trial_cols{i} );
  assert( any(col_ind), 'Could not find column ''%s''', desired_trial_cols{i} );
  indices.(desired_trial_cols{i}) = cell2mat( trial_info(:, col_ind) );
end

meta_struct = struct();
for i = 1:numel(meta_fields)
  meta_struct.(meta_fields{i}) = ...
    char( meta(strcmp(meta_fields, meta_fields{i})) );
end

complete_true = true( size(trial_info, 1), 1 );

%   define outcomes

cue_type = indices.cueType;
fixed_on = indices.fix;

inds.outcomes.self =  (cue_type == 0 & fixed_on == 1) | (cue_type == 1 & fixed_on == 2);
inds.outcomes.both =  (cue_type == 1 & fixed_on == 1) | (cue_type == 0 & fixed_on == 2);
inds.outcomes.other = (cue_type == 2 & fixed_on == 1) | (cue_type == 3 & fixed_on == 2);
inds.outcomes.none =  (cue_type == 3 & fixed_on == 1) | (cue_type == 2 & fixed_on == 2);
inds.outcomes.errors = ...
  ~any( [inds.outcomes.self, inds.outcomes.both, inds.outcomes.other, inds.outcomes.none], 2 );

%   define trialtypes
inds.trialtypes.choice = logical( indices.trialType );
inds.trialtypes.cued = ~inds.trialtypes.choice;
%   define magnitudes
inds.magnitudes.high = indices.magnitude == 3;
inds.magnitudes.medium = indices.magnitude == 2;
inds.magnitudes.low = indices.magnitude == 1;
inds.magnitudes.no_reward = ...
  ~any( [inds.magnitudes.high, inds.magnitudes.medium, inds.magnitudes.low], 2 );
%   define session
inds.sessions = struct( ['session__' meta_struct.session], complete_true );
%   define filename
inds.files = struct( ['file__' filename], complete_true );
%   define actor monkey
inds.monkeys = struct( meta_struct.actor, complete_true );
%   define recipient monkey
inds.recipients = struct( meta_struct.recipient, complete_true );
%   define drugs
inds.drugs = struct( meta_struct.drug, complete_true );
%   define blocks
blocks = unique( indices.folder );
for i = 1:numel(blocks)
  current_ind = indices.folder == blocks(i);
  inds.blocks.(sprintf('block__%d', blocks(i))) = current_ind; 
end
%   define trials
trials = unique( indices.trial );
for i = 1:numel(trials)
  current_ind = indices.trial == trials(i);
  inds.trials.(sprintf('trial__%d', trials(i))) = current_ind;
end

categories = fieldnames( inds );
sparse_labels_inputs = {};
for i = 1:numel(categories)
  current_cat = inds.(categories{i});
  labels = fieldnames( current_cat );
  for k = 1:numel(labels)
    current_index = current_cat.(labels{k});
    in = struct( 'label', labels{k}, 'category', categories{i}, 'index', current_index );
    sparse_labels_inputs = [ sparse_labels_inputs, in ];
  end
end

labels = SparseLabels( sparse_labels_inputs );

end