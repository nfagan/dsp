function pref = dsp__behavior_preference_index_within( obj, within, outcomes )

if ( nargin < 3 )
  outcomes = { {'both', 'self'}, {'other', 'none'} };
end
if ( ~iscell(within) ), within = { within }; end;
assert( iscellstr(within), 'Specify within as a cell array of strings' );
assert( isa(obj, 'Container'), 'Input must be a Container; was a ''%s''' ...
  , class(obj) );
inds = obj.get_indices( within );
pref = Container();
for i = 1:numel(inds)
  extr = obj( inds{i} );
  one_pref = dsp__behavior__preference_index( extr, outcomes );
  if ( isempty(one_pref) ), continue; end;
  for k = 1:numel(within)
    one_pref( within{k} ) = char( unique(extr(within{k})) );
  end
  pref = pref.append( one_pref );
end


end