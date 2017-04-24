function dsp__correlate_behavior()

io = DSP_IO();

pl = ContainerPlotter();

resolution = 'per_day';

is_z = false;

if ( is_z )
  base_load_path = fullfile( pathfor('ANALYSES'), '020317', 'ztrans' );
  base_save_path = fullfile( pathfor('PLOTS'), '030917', 'behavior', 'ztrans' );
else
  base_load_path = fullfile( pathfor('ANALYSES'), '020317' );
  base_save_path = fullfile( pathfor('PLOTS'), '042017', 'behavior_correlations' );
end

combs = allcomb( { ...
    {'non_common_averaged'} ...
  , {'coherence'} ...
  , {'targacq'} ...
  , {'without_errors_pre_and_post'} ...
  , {'pro_v_anti'} ...
});

behav_measures = { 'reaction_time', 'lateLookCount', 'lateBottleLookCount' };
[behav, orig_behav, trial_fields] = dsp__get_column_behavior_measures( behav_measures );
pref = dsp__behavior_preference_index_within( behav{1} ...
  , {'days', 'monkeys', 'drugs', 'administration', 'trialtypes'} ...
  , {{'self', 'both'}, {'other', 'none'}} );
gaze_frequency = dsp__get_gaze_frequency( dsp__get_combined_looking_measures(orig_behav, trial_fields) );

behav.bottle_gaze_frequency = gaze_frequency.only( 'bottle' );
behav.monkey_gaze_frequency = gaze_frequency.only( 'monkey' );
behav = behav.each( @(x) SignalContainer(x.data, x.labels) );
behav = behav.update_label_sparsity();
behav = behav.columnize();
pref = SignalContainer( pref.data, pref.labels );
pref = pref.replace( 'self:both', 'selfMinusBoth' );
pref = pref.replace( 'other:none', 'otherMinusNone' );

% time_freq_windows = { {[-250 0], [4 20]}, {[50 300], [4 20]}, {[-100 200], [30 50]} };
time_freq_windows = { {[0 200], [45 60]} };
% time_freq_windows = { {[-100 200], [30 50]} };

for i = 1:size( combs, 1 )
  method = combs{i, 1};
  measure_type = combs{i, 2};
  epoch = combs{i, 3};
  z_type = combs{i, 4};
  manipulation = combs{i, 5};
  
  if ( is_z )
    full_load_path = fullfile( base_load_path, z_type, method, measure_type, epoch );
    z = io.load( full_load_path );
    infs = any( any(isinf(z.data), 3), 2 );
    z = z.keep( ~infs );
  else
    full_load_path = fullfile( base_load_path, method, measure_type, epoch );
    monk_combs = allcomb( {{'hitch','kuro'}, {'oxytocin', 'saline'}} );
    %   add first two blocks of hitch non-injection if not looking at drug
    %   effect
    switch ( manipulation )
      case { 'pro_minus_anti', 'pro_v_anti', 'per_outcome' }
        monk_combs(end+1, :) = { 'hitch', 'unspecified' };
    end
    z = Container();
    for k = 1:size(monk_combs, 1)
      current = io.load( full_load_path, 'only', monk_combs(k, :) );
      current = current.rm( {'cued', 'errors'} );
      z = z.append( current );
    end
    if ( i == 1 )
      base_save_path = fullfile( base_save_path, method );
    end
    z = z.keep_within_range( .3 );
    z = dsp__remove_bad_days_and_blocks( z );
%     meaned = z.time_freq_mean( [], [0 100] );
%     within_std_threshold = dsp__std_threshold_index( meaned ...
%       , {'regions', 'monkeys', 'drugs', 'outcomes'}, 2 );
%     z = z.keep( within_std_threshold );
  end
  
  behav = behav.each( @dsp__remove_bad_days_and_blocks );
  pref = dsp__remove_bad_days_and_blocks( pref );
  
  switch ( manipulation )
    case 'pro_v_anti'
      to_rm = { 'cued', 'errors', 'post' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'days', 'sites' };
      else m_within = { 'outcomes', 'days' };
      end
      z = z.mean_within( m_within );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      if ( isequal(resolution, 'per_site') )
        require_per = { 'days', 'sites' };
      else require_per = { 'days' };
      end
      z = z.do_per( require_per, @dsp__require_outcomes );
      z = z.subtract_across_mult( sub_across{:} );
      behav = behav.rm( to_rm );
      behav = behav.mean_within( {'outcomes', 'days'} );
      behav = behav.subtract_across_mult( sub_across{:} );
      pref = pref.rm( to_rm );
      pref = pref.mean_within( {'outcomes', 'days'} );
      behav.preference = pref;
      panels_are = { 'outcomes' };
      plot_shape = [];
    case 'pro_v_anti_post_minus_pre'
      to_rm = { 'cued', 'errors', 'unspecified' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'administration', 'drugs', 'days', 'sites' };
      else m_within = { 'outcomes', 'administration', 'drugs', 'days' };
      end
      z = z.mean_within( m_within );
      z = dsp__remove_if_subtraction_fails( z, 'days', 'post', 'pre', 'postMinusPre' );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      if ( isequal(resolution, 'per_site') )
        require_per = { 'days', 'sites' };
      else require_per = { 'days' };
      end
      z = z.do_per( require_per, @dsp__require_outcomes );
      z = z.subtract_across_mult( sub_across{:} );
      behav = behav.rm( to_rm );
      behav = behav.mean_within( {'outcomes', 'days', 'administration', 'drugs'} );
      behav = behav.each( @dsp__remove_if_subtraction_fails, 'days', 'post', 'pre', 'postMinusPre' );
      behav = behav.subtract_across_mult( sub_across{:} );
      pref = pref.rm( to_rm );
      pref = pref.mean_within( {'outcomes', 'days', 'administration', 'drugs'} );
      pref = dsp__remove_if_subtraction_fails( pref, 'days', 'post', 'pre', 'postMinusPre' );
      behav.preference = pref;
      panels_are = { 'administration', 'drugs' };
      plot_shape = [1 2];
    case 'pro_v_anti_pre_v_post'
      to_rm = { 'cued', 'errors', 'unspecified' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'administration', 'drugs', 'days', 'sites' };
      else m_within = { 'outcomes', 'administration', 'drugs', 'days' };
      end
      z = z.mean_within( m_within );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      if ( isequal(resolution, 'per_site') )
        require_per = { 'days', 'sites' };
      else require_per = { 'days' };
      end
      z = z.do_per( require_per, @dsp__require_outcomes );
      z = z.subtract_across_mult( sub_across{:} );
      behav = behav.rm( to_rm );
      behav = behav.mean_within( {'outcomes', 'days', 'administration', 'drugs'} );
      behav = behav.subtract_across_mult( sub_across{:} );
      pref = pref.rm( to_rm );
      pref = pref.mean_within( {'outcomes', 'days', 'administration', 'drugs'} );
      behav.preference = pref;
      panels_are = { 'drugs', 'administration' };
      plot_shape = [2 2];
  end  
  if ( isequal(resolution, 'per_site') )  
    enumed = z.enumerate( 'days' );
    rebuilt_measure = Container();
    rebuilt_behav = Structure.create( behav.fields(), Container() );
    rebuilt_behav = rebuilt_behav.each( @(x) SignalContainer(x.data, x.labels) );
    for k = 1:numel(enumed)
      current = enumed{k};
      sites = current( 'sites' );
      day = current( 'days' );
      current_behav = behav.only( day );
      for j = 1:numel(sites)
        extr = current.only( sites{j} );
        for h = 1:numel( behav.fields() )
          matched_behav = extr.match( current_behav{h} );
          rebuilt_behav{h} = rebuilt_behav{h}.append( matched_behav );
        end
        rebuilt_measure = rebuilt_measure.append( extr );
      end
    end
  else
    rebuilt_behav = Structure.create( behav.fields(), Container() );
    rebuilt_behav = rebuilt_behav.each( @(x) SignalContainer(x.data, x.labels) );
    for h = 1:numel( behav.fields() )
      rebuilt_behav{h} = z.match( behav{h} );
    end
    rebuilt_measure = z;
  end
  rebuilt_measure = rebuilt_measure.rm_fields( {'sites', 'channels', 'regions', 'epochs'} );
  
  rebuilt_measure = rebuilt_measure.columnize();
  rebuilt_behav = rebuilt_behav.columnize();
  for j = 1:numel( time_freq_windows )
    time_freq_window = time_freq_windows{j};
    meaned = rebuilt_measure.time_freq_mean( time_freq_window{:} );
    str_time = sprintf( '%d_to_%d_ms', time_freq_window{1}(1), time_freq_window{1}(2) );
    str_freq = sprintf( '%d_to_%d_hz', time_freq_window{2}(1), time_freq_window{2}(2) );
    nans = rebuilt_behav.each( @(x) any(isnan(x.data), 2) );
    rm_nans = false( size(nans{1}) );
    for k = 1:numel( rebuilt_behav.fields() )
      rm_nans = rm_nans | nans{k};
    end
    if ( any(rm_nans) )
      meaned = meaned.keep( ~rm_nans );
      rebuilt_behav = rebuilt_behav.keep( ~rm_nans );
    end
    behav_fields = rebuilt_behav.fields();
    for k = 1:numel( behav_fields )      
      full_save_path = fullfile( base_save_path, method, measure_type, epoch, manipulation );
      if ( exist(full_save_path, 'dir') ~= 7 ), mkdir( full_save_path ); end;
      filename = sprintf( '%s_%s_%s', behav_fields{k}, str_time, str_freq );
      filename = fullfile( full_save_path, filename );
      pl.default();
      pl.y_label = sprintf( 'Difference in %s', behav_fields{k} );
      if ( is_z )
        pl.x_label = sprintf( 'Z-scored %s', measure_type );
      else pl.x_label = sprintf( 'Non-z-scored %s', measure_type );
      end
      pl.add_fit_line = true;
%       pl.match_fit_line_color = false;
%       pl.set_colors = 'manual';
%       pl.colors = 'blue';
      pl.marker_size = 20;
      pl.shape = plot_shape;
      pl.scatter( meaned, rebuilt_behav{k}, 'outcomes', panels_are );
      saveas( gcf, filename, 'epsc' ); 
      saveas( gcf, filename, 'png' );
    end  
  end
end


end