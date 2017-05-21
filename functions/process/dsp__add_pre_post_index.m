function obj = dsp__add_pre_post_index(obj)

first_two_block_day = datenum( '01142017', 'mmddyyyy' );

is_pre = false( shape(obj, 1), 1 );
trials = arrayfun( @(x) ['trial__' num2str(x)], 0:255, 'un', false );
days = unique( obj('days') );

for i = 1:numel(days)
  fprintf( '\n Processing day %d of %d', i, numel(days) );
  day_ind = obj.where( days{i} );
  one = obj( day_ind );
  current_trials = unique( one('trials') );
  current_trials = cellfun( @(x) str2double(x(8:end)), current_trials );
  largest_trial = sprintf( 'trial__%d', max(current_trials) );
  where_in_trials = find( strcmp(trials, largest_trial) );
  search_trials = trials(1:where_in_trials);
  day = days{i};
  date_num = datenum( day(6:end), 'mmddyyyy' );
  if ( date_num >= first_two_block_day )
    blocks = { 'block__1', 'block__2' };
  else blocks = { 'block__1' };
  end
  session_ind = obj.where( 'session__1' );
  block_ind = obj.where( blocks );
  trial_ind = obj.where( search_trials );
  if ( ~any(session_ind) )
    sesh = unique( obj('sessions') );
    if ( numel(sesh) > 1 )
      error( ['The object has more than one session, but none of them are' ...
        , ' the first session'] );
    end
  end
  are_pre = day_ind & session_ind & block_ind & trial_ind;
%   assert( any(are_pre), 'Incorrect search criteria for pre' );
  is_pre = is_pre | are_pre;
end

if ( isa(obj.labels, 'SparseLabels') )
  labels = obj.labels;
  labels.labels{end+1} = 'pre';
  labels.categories{end+1} = 'administration';
  labels.indices = [labels.indices sparse(is_pre)];
  if ( ~all(is_pre) )
    labels.labels{end+1} = 'post';
    labels.categories{end+1} = 'administration';
    labels.indices = [labels.indices sparse(~is_pre)];
  end
  obj.labels = labels;
else
  new_labs = cell( shape(obj, 1), 1 );
  new_labs(is_pre) = { 'pre' };
  new_labs(~is_pre) = { 'post' };
  obj = obj.add_field( 'administration', new_labs );
end


end