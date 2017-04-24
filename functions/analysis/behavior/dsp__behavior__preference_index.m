function pref = dsp__behavior__preference_index( obj, outcomes )

if ( nargin < 2 )
  outcomes = { {'both', 'self'}, {'other', 'none'} };
end
pref = Container();
for i = 1:numel(outcomes)
  out1 = obj.only( outcomes{i}{1} );
  out2 = obj.only( outcomes{i}{2} );
  if ( isempty(out1) || isempty(out2) )
    fprintf( ['\n ! dsp__behavior__preference_index: WARNING, no data' ...
      , ' matched the provided outcomes'] );
    continue;
  end
  label = strjoin( outcomes{i}, ':' );
  n_out1 = shape( out1, 1 );
  n_out2 = shape( out2, 1 );
  ind = (n_out1 - n_out2) / (n_out1 + n_out2 );
  out1 = out1.collapse_non_uniform();
  out1 = out1(1);
  out1.data = ind;
  out1('outcomes') = label;
  pref = pref.append( out1 );
end


end