function dsp__create_means()

base_load_path = fullfile( pathfor('ANALYSES'), '020317' );

io = DSP_IO();
io.FORCE_OVERWRITE = true;

measure_combs = allcomb( { ...
    {'non_common_averaged'} ...
  , {'coherence', 'normalized_power_within_pre_post'} ...
  , {'reward', 'targacq'} ...
} );

monk_combs = allcomb( { ...
    {'hitch', 'kuro'} ...
  , {'oxytocin', 'saline'} ...
} );

monk_combs(end+1, :) = { 'hitch', 'unspecified' };

for i = 1:size(measure_combs, 1)
  ref_type = measure_combs{i, 1};
  measure = measure_combs{i, 2};
  epoch = measure_combs{i, 3};
  
  full_load_path = fullfile( base_load_path, ref_type, measure, epoch );
  full_save_path = fullfile( base_load_path, ref_type, [measure '__meaned'], epoch );
  if ( exist(full_save_path, 'dir') ~= 7 ), mkdir( full_save_path ); end;
  
  loaded = Container();
  
  for k = 1:size(monk_combs, 1)
    one = io.load( full_load_path, 'only', monk_combs(k, :) );
    drug = monk_combs{k, 2};
    if ( isequal(drug, 'unspecified') )
      one = one.only( {'block__1', 'block__2'} );
      one( 'administration' ) = 'pre';
    end
    one = one.keep_within_range( .3 );
    one = dsp__remove_bad_days_and_blocks( one );
    m_within = { 'days', 'channels', 'outcomes', 'administration', 'trialtypes' };
    collapse_across = { 'trials', 'blocks', 'recipients', 'sessions', 'magnitudes' };
    meaned = one.do( m_within, @mean );
    meaned = meaned.collapse( collapse_across );    
    loaded = loaded.append( meaned );
  end
  
  loaded = loaded.update_label_sparsity();
  loaded = loaded.columnize();
  
  io.save( loaded, full_save_path );
end