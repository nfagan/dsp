function all_ids = dsp__get_trial_ids( obj )

if ( isa(obj, 'Container') )
  inds = obj.get_indices( 'days' );
else inds = obj.getindices( 'days' );
end
cumulative = 0;
all_ids = nan( shape(obj, 1), 1 );

for i = 1:numel(inds)
  fprintf( '\n Processing %d of %d', i, numel(inds) );
  extr = obj(inds{i});
  channels = unique( extr('channels') );
  day = char( unique(extr('days')) );
  for k = 1:numel(channels)
    ind = extr.where( channels{k} );
    if ( k == 1 )
      ids = cumulative+1:cumulative+sum(ind);
      ids = ids(:);
    end
    full_ind = obj.where( {day, channels{k}} );
    all_ids( full_ind ) = ids;
  end
  cumulative = cumulative + sum(ind);
end

end