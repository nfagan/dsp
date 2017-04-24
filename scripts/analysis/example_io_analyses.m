function example_io_analyses()

do_coherence = false;
do_normalized_power = true;
do_raw_power = false;

%%  COHERENCE

io = DSP_IO();

if ( do_coherence )

  combs = allcomb( { ...
      {'targon'} ...
    , {'non_common_averaged'} ...
    , {'coherence'} ...
  } );

  base_load_path = 'H:\SIGNALS\processed';
  base_save_path = 'E:\nick_data\ANALYSES\020317';

  for k = 1:size( combs, 1 );
    epoch = combs{k, 1};
    method = combs{k, 2};
    coh_type = combs{k, 3};
    signal_path = fullfile( base_load_path, method, epoch );
    save_path = fullfile( base_save_path, method, coh_type, epoch );

    if ( exist(save_path, 'dir') ~= 7 ), mkdir( save_path ); end;

    days = io.get_days( signal_path );
    for i = 1:numel(days)
      fprintf( '\n\n\n\n %d of %d', i, numel(days) );
      day = io.load( signal_path, 'only', days{i} );
      if ( isequal(method, 'non_common_averaged') )
        day = dsp__ref_subtract_within_day( day );
      else day = day.remove( 'ref' );
      end
      day = day.filter();
      day = day.update_range();
      if ( isequal(coh_type, 'coherence_non_multitapered') )
        day.frequencies = 0:200;
        coh = dsp__analysis__coherence_all( day, 'coherenceType', 'nonCronux' );
      else
        coh = dsp__analysis__coherence_all( day );
      end
      coh = coh.update_label_sparsity();
      io.save( coh, save_path );
    end
  end

end

%%  NORMALIZED POWER

if ( do_normalized_power )

  combs = allcomb( { ...
      {'targon'} ...
    , {'non_common_averaged'} ...
    , {'normalized_power_within_pre_post'} ...
  } );

  norm_by_epoch = 'magcue';

  base_load_path = 'H:\SIGNALS\processed';
  base_save_path = 'E:\nick_data\ANALYSES\020317';

  for k = 1:size( combs, 1 )
    epoch = combs{k, 1};
    method = combs{k, 2};
    power_type = combs{k, 3};

    cue_path = fullfile( base_load_path, method, norm_by_epoch );
    norm_path = fullfile( base_load_path, method, epoch );
    save_path = fullfile( base_save_path, method, power_type, epoch );

    if ( exist(save_path, 'dir') ~= 7 ), mkdir( save_path ); end;

    days = io.get_days( cue_path );

    structure = Structure();

    for i = 1:numel(days)
      structure.cue_day = io.load( cue_path, 'only', days{i} );
      structure.norm_day = io.load( norm_path, 'only', days{i} );

      structure = structure.update_range();
      if ( isequal(method, 'non_common_averaged') )
        structure = structure.each( @dsp__ref_subtract_within_day );
      else structure = structure.remove( 'ref' ); 
      end
      structure = structure.filter();
      structure = structure.update_range();
      
      structure.norm_day.params.removeNormPowerErrors = true;
      structure.cue_day.params.removeNormPowerErrors = true;
      
      if ( isequal(power_type, 'normalized_power_within_pre_post') )
        pre = structure.only( 'pre' );
        post = structure.only( 'post' );
        pre_pow = dsp__analysis__norm_power_all( pre.norm_day, pre.cue_day );
        post_pow = dsp__analysis__norm_power_all( post.norm_day, post.cue_day );
        pre_pow = pre_pow.update_label_sparsity();
        post_pow = post_pow.update_label_sparsity();
        pow = pre_pow.append( post_pow );
        pow = pow.columnize();
      else
        pow = dsp__analysis__norm_power_all( structure.norm_day, structure.cue_day );
        pow = pow.update_label_sparsity();
      end
      io.save( pow, save_path );
    end
  end

end

%%  RAW POWER

if ( do_raw_power )

  combs = allcomb( { ...
      {'reward'} ...
    , {'non_common_averaged'} ...
  } );

  base_load_path = 'H:\SIGNALS\processed';
  base_save_path = 'E:\nick_data\ANALYSES\020317';

  for k = 1:size( combs, 1 )
    epoch = combs{k, 1};
    method = combs{k, 2};

    norm_path = fullfile( base_load_path, method, epoch );
    save_path = fullfile( base_save_path, method, 'raw_power', epoch );

    if ( exist(save_path, 'dir') ~= 7 ), mkdir( save_path ); end;

    days = io.get_days( norm_path );

    for i = 1:numel(days)
      norm_day = io.load( norm_path, 'only', days{i} );
      norm_day = norm_day.update_range();
      if ( isequal(method, 'non_common_averaged') )
        norm_day = dsp__ref_subtract_within_day( norm_day );
      else norm_day = norm_day.remove( 'ref' ); 
      end
      norm_day = norm_day.filter();
      norm_day = norm_day.update_range();
      pow = dsp__analysis__raw_power_all( norm_day );
      pow = pow.update_label_sparsity();
      io.save( pow, save_path );
    end
  end

end

end
