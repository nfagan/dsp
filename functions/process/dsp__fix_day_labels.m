function obj = dsp__fix_day_labels( obj )

sessions = obj( 'sessions' );
days = cellfun( @(x) x(12:19), sessions, 'un', false );

if ( isa(obj.labels, 'Labels') )
  obj = obj.add_field( 'days', days ); return;
end

labels = obj.labels;
unqs = unique( days );
for i = 1:numel(unqs)
  matches = find( strcmp(days, unqs{i}) );
  ind = rep_logic( labels, false );
  for k = 1:numel(matches)
    ind = ind | labels.where( sessions(matches(k)) );
  end
  labels.labels{end+1} = unqs{i};
  labels.categories{end+1} = 'days';
  labels.indices = [labels.indices ind];
end

obj.labels = labels;

end