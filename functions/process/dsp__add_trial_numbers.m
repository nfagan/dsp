function obj = dsp__add_trial_numbers( obj )

inds = obj.getindices( 'days' );
cumulative = 0;
all_trials = obj( 'channels' );

for i = 1:numel(inds)
  fprintf( '\n Processing %d of %d', i, numel(inds) );
  extr = obj(inds{i});
  channels = unique( extr('channels') );
  day = char( unique(extr('days')) );
  for k = 1:numel(channels)
    ind = extr.where( channels{k} );
    if ( k == 1 )
      trials = arrayfun( @(x) ['trial__' num2str(x)] ...
        , cumulative+1:cumulative+sum(ind), 'un', false );
    end
    full_ind = obj.where( {day, channels{k}} );
    all_trials( full_ind ) = trials;
  end
  cumulative = cumulative + sum(ind);
end

obj = obj.addfield( 'trials' );
obj('trials') = all_trials;

end