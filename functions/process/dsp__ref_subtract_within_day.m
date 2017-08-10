function others = dsp__ref_subtract_within_day( obj )

%   REFERENCE_SUBTRACT_WITHIN_DAY -- For each day, subtract the ref
%     electrode trace from each additional channel.
%
%     IN:
%       - `obj` (SignalContainer)

if ( isa(obj, 'SignalObject') )
  fs = obj.fs; time = obj.time; obj = obj.to_container(); convert_back = true;
else convert_back = false;
end

ref = only( obj, 'ref' );
others = remove( obj, 'ref' );

indices = get_indices( others, { 'days', 'regions' } );

for i = 1:numel(indices)
  fprintf( '\n ! dsp__ref_subtract_within_day: Processing %d of %d', i, numel(indices) );
  extr = others( indices{i} );
  ref_complement = ref.only( char(unique(extr('days'))) );
  channels = unique( extr('channels') );
  for k = 1:numel(channels)
    ind = extr.where( channels{k} );
    subtracted = opc( extr(ind), ref_complement, {'channels', 'regions'}, @minus );
    if ( ~any(subtracted.data(:) > 0) )
      error( 'subtracted a channel from itself' );
    end
    extr.data(ind, :) = subtracted.data;
  end
  others.data(indices{i},:) = extr.data;
end

if ( convert_back )
  others = SignalObject( others.to_data_object(), fs, time );
end

if ( isa(others, 'SignalContainer') )
  others = others.update_range();
end

end