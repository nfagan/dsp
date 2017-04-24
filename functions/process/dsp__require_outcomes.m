function obj = dsp__require_outcomes( obj, outcomes )

if ( nargin < 2 ), outcomes = {'self', 'both', 'other', 'none'}; end;

for i = 1:numel(outcomes)
  ind = obj.where( outcomes{i} );
  if ( ~any(ind) ), obj = make_empty( obj ); return; end;
  if ( i == 1 )
    N = sum( ind );
  elseif ( N ~= sum(ind) )
    obj = make_empty( obj ); return;
  end
end

end

function obj = make_empty(obj)

obj = obj(1);
obj = obj.keep( false );

end