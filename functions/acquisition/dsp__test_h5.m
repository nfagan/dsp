function dsp__test_h5()

c = allcomb( { ...
    { 'non_common_averaged'} ...
  , { 'coherence__meaned', 'coherence', 'normalized_power_within_pre_post__meaned', 'normalized_power_within_pre_post' } ...
  , { 'reward', 'targacq' }
} );

h5_file = fullfile( pathfor('DATABASE'), 'dsp2.h5' );
% delete( h5_file );

dsp_io = DSP_IO();
io = dsp_h5();
io.create( h5_file );

for k = 1:size(c, 1)
  fprintf( '\n Iteration %d of %d', k, size(c, 1) );
  ref_type = c{k, 1};
  measure_type = c{k, 2};
  epoch = c{k, 3};

  measure_path = fullfile( pathfor('ANALYSES'), '020317', ref_type, measure_type, epoch );
  if ( ~isempty(strfind(measure_type, 'meaned')) )
    resolution = 'meaned';
    measure_type = rm_meaned( measure_type );
  else
    resolution = 'per_trial';
  end
  
  group_name = sprintf( '/Measures/%s/%s/%s/%s', ref_type, measure_type, resolution, epoch );
  
  io.create_group( group_name );

  days = dsp_io.get_days( measure_path );
  for i = 1:numel(days)
    coh = dsp_io.load( measure_path, 'only', days{i} );
    io.add( coh, group_name );
  end
  
end

end

function str = rm_meaned( str )

ind = strfind( str, '__meaned' );
str = str( 1:ind-1 );

end
