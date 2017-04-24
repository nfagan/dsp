function bad_days = dsp__get_days_without_outcomes( obj, within, outcomes )
if ( nargin < 3 ), outcomes = { 'self', 'both', 'other', 'none'}; end;
days = obj.enumerate( 'days' );
bad_days = {};
for i = 1:numel(days)
  day = days{i};
  objs = obj.enumerate( within );
  for k = 1:numel(objs)
    exists = all( objs{k}.contains(outcomes) );
    if ( ~exists )
      bad_days{end+1} = char( day('days') );
    end
  end
end

end