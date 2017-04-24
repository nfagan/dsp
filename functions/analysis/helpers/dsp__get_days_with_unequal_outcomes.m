function bad_days = dsp__get_days_with_unequal_outcomes( obj, within, outcomes )
if ( nargin < 3 ), outcomes = { 'self', 'both', 'other', 'none'}; end;
days = obj.enumerate( 'days' );
bad_days = {};
for i = 1:numel(days)
  day = days{i};
  objs = day.enumerate( within );
  for k = 1:numel(objs)
    curr_obj = objs{k};
    exists = all( curr_obj.contains(outcomes) );
    if ( ~exists )
      bad_days{end+1} = char( day('days') );
      break;
    end
    current = zeros( 1, numel(outcomes) );
    for j = 1:numel(outcomes)
      current(j) = full( sum(curr_obj.where(outcomes{j})) );
    end
    if ( k == 1 )
      nums = current;
      continue;      
    end
    matches = all( nums == current );
    if ( ~matches )
      bad_days{end+1} = char( day('days') );
      break;
    end
  end
end

end