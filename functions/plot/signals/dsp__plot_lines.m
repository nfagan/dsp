function dsp__plot_lines()

io = DSP_IO();

pl = ContainerPlotter();

resolution = 'per_site';

plot_time = false;
% windows = { [20 40] };
windows = { [0 300] };
% time_freq_windows = { {[-100 200], [30 50]} };

is_z = false;

if ( is_z )
  base_load_path = fullfile( pathfor('ANALYSES'), '020317', 'ztrans' );
  base_save_path = fullfile( pathfor('PLOTS'), '030917', 'lines', 'ztrans' );
else
  base_load_path = fullfile( pathfor('ANALYSES'), '020317' );
  base_save_path = fullfile( pathfor('PLOTS'), '042217', 'lines' );
end
% { 'pro_v_anti_oxy_v_sal', 'pro_v_anti', 'pro_v_anti_oxy_minus_sal' } ...
% combs = allcomb( { ...
%     { 'non_common_averaged' } ...
%   , { 'normalized_power_within_pre_post' } ...
%   , { 'targacq', 'reward' } ...
%   , { 'without_errors_pre_and_post' } ...
%   , { 'pro_v_anti_oxy_v_sal', 'pro_v_anti_oxy_minus_sal' } ...
% });

combs = allcomb( { ...
    { 'non_common_averaged' } ...
  , { 'normalized_power_within_pre_post' } ...
  , { 'targacq' } ...
  , { 'without_errors_pre_and_post' } ...
  , { 'pro_v_anti_oxy_v_sal' } ...
});

% combs = allcomb( { ...
%     { 'non_common_averaged' } ...
%   , { 'coherence' } ...
%   , { 'targacq' } ...
%   , { 'without_errors_pre_and_post' } ...
%   , { 'pro_v_anti' } ...
% });

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
      drug = monk_combs{k, 2};
      if ( isequal(drug, 'unspecified') )
        current = current.only( {'block__1', 'block__2'} );
        current( 'administration' ) = 'pre';
      end
      z = z.append( current );
    end
    if ( i == 1 )
      base_save_path = fullfile( base_save_path, method );
    end
    
    z = z.keep_within_range( .3 );
    z = dsp__remove_bad_days_and_blocks( z );
    
    if ( ~is_z )
      bad_sites = dsp__identify_bad_sites( z, {'outcomes', 'administration'} );
      for k = 1:size(bad_sites, 1)
        z = z.only_not( bad_sites(k, :) );
      end
    end
%     meaned = z.time_freq_mean( [], [0 100] );
%     within_std_threshold = dsp__std_threshold_index( meaned ...
%       , {'regions', 'monkeys', 'drugs', 'outcomes'}, 2 );
%     z = z.keep( within_std_threshold );
  end
  
  switch ( manipulation )
    case { 'pro_v_anti', 'pro_minus_anti' }
      to_rm = { 'cued', 'errors', 'post' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'days', 'regions', 'channels' };
      else m_within = { 'outcomes', 'days', 'regions' };
      end
      z = z.mean_within( m_within );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      if ( isequal(resolution, 'per_site') )
        require_per = { 'days', 'regions', 'channels' };
      else require_per = { 'days', 'regions' };
      end
      z = z.do_per( require_per, @dsp__require_outcomes );
      z = z.subtract_across_mult( sub_across{:} );
      if ( isequal(manipulation, 'pro_minus_anti') )
        z = z.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
        lines_are = { 'outcomes' };
        panels_are = { 'trialtypes', 'regions' };
        plot_shape = [];
      else
        if ( isequal(measure_type, 'coherence') )
          lines_are = { 'outcomes' };
          panels_are = { 'trialtypes', 'regions' };
        else
          lines_are = { 'regions' };
          panels_are = { 'trialtypes', 'outcomes' };
        end
%         lines_are = { 'outcomes' };
        plot_shape = [];
      end
    case 'pro_v_anti_oxy_minus_sal'
      to_rm = { 'cued', 'errors' };
      z = z.rm( to_rm );
      m_within = { 'outcomes', 'regions', 'drugs', 'administration' };
      z = z.mean_within( m_within );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      z = z.subtract_across_mult( sub_across{:} );
      z = z.subtract_across( 'post', 'pre', 'postMinusPre' );
      z = z.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      lines_are = { 'regions' };
      panels_are = { 'drugs' };
      plot_shape = [];
    case 'pro_v_anti_oxy_v_sal'
      to_rm = { 'cued', 'errors' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'days', 'regions', 'channels', 'drugs', 'administration' };
        require_per = { 'days', 'regions', 'channels', 'administration' };
      else
        m_within = { 'outcomes', 'days', 'regions', 'drugs', 'administration' };
        require_per = { 'days', 'regions', 'administration' };
      end
      z = z.mean_within( m_within );
%       z = z.do_per( require_per, @dsp__require_outcomes );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      z = z.subtract_across_mult( sub_across{:} );
%       z = z.do_per( {'days', 'regions', 'channels', 'outcomes'}, @dsp__require_outcomes, {'post', 'pre'} );
      z = z.subtract_across( 'post', 'pre', 'postMinusPre' );
      lines_are = { 'drugs' };
      panels_are = { 'outcomes', 'regions' };
      plot_shape = [];
    case 'pro_minus_anti_oxy_minus_sal'
%       to_rm = { 'cued', 'errors' };
%       z = z.rm( to_rm );
%       if ( isequal(resolution, 'per_site') )
%         m_within = { 'outcomes', 'days', 'sites', 'drugs', 'administration' };
%         require_per = { 'days', 'sites' };
%       else
%         m_within = { 'outcomes', 'days', 'drugs', 'administration' };
%         require_per = { 'sites' };
%       end
%       z = z.mean_within( m_within );
%       sub_across = { {'self', 'both', 'selfMinusBoth'} ...
%         , {'other', 'none', 'otherMinusNone'} };
%       z = z.do_per( require_per, @dsp__require_outcomes );
%       z = z.subtract_across_mult( sub_across{:} );
%       z = z.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
%       z = z.subtract_across( 'post', 'pre', 'postMinusPre' );
%       z = z.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      to_rm = { 'cued', 'errors', 'unspecified' };
      z = z.rm( to_rm );
      z = z.mean_within( {'outcomes', 'regions', 'drugs', 'administration'} );
      sub_across = { {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} };
      z = z.subtract_across_mult( sub_across{:} );
      z = z.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      z = z.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      z = z.subtract_across( 'post', 'pre', 'postMinusPre' );
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
      lines_are = { 'outcomes' };
      panels_are = { 'administration', 'drugs' };
      plot_shape = [2 1];
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
      lines_are = { 'outcomes' };
      panels_are = { 'drugs', 'administration' };
      plot_shape = [2 2];
   case 'pro_minus_anti_post_minus_pre_sal_v_oxy'
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
      z = z.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      lines_are = { 'drugs' };
      panels_are = { 'administration', 'outcomes' };
      plot_shape = [];
    case {'received_v_forgone', 'received_minus_forgone' }
      to_rm = { 'cued', 'errors', 'post' };
      z = z.rm( to_rm );
      if ( isequal(resolution, 'per_site') )
        m_within = { 'outcomes', 'days', 'regions', 'channels' };
      else m_within = { 'outcomes', 'days', 'regions' };
      end
      z = z.mean_within( m_within );
      z = z.replace( {'other', 'none'}, 'forgone' );
      z = z.replace( {'self', 'both'}, 'received' );
      z = z.mean_within( m_within );
      if ( isequal(manipulation, 'received_minus_forgone') )
        z = z.subtract_across( 'received', 'forgone', 'receivedMinusForgone' );
        lines_are = { 'outcomes' };
        panels_are = { 'trialtypes', 'regions' };
        plot_shape = [];
      else
        lines_are = { 'outcomes' };
        panels_are = { 'trialtypes', 'regions' };
        plot_shape = [];
      end
  end  
  
  for j = 1:numel( windows )
    window = windows{j};
    if ( plot_time )
      meaned = z.freq_mean( window );
      meaned = meaned.keep_within_times( [-300 500] );
      new_data = zeros( meaned.shape(1), meaned.shape(3) );
      new_data(:, :) = meaned.data;
      meaned.data = new_data;
      x = meaned.get_time_series();
      base_filename = sprintf( '%d_to_%d_hz', window(1), window(2) );
      x_label = 'Time (ms)';
      y_lim = [];
    else
      meaned = z.time_mean( window );
      meaned = meaned.keep_within_freqs( [0 100] );
      x = meaned.frequencies;
      base_filename = sprintf( '%d_to_%d_ms', window(1), window(2) );
      x_label = 'Hz';
      y_lim = [];
%       y_lim = [-.75 .75];
    end
    full_save_path = fullfile( base_save_path, method, measure_type, epoch, manipulation );
    if ( exist(full_save_path, 'dir') ~= 7 ), mkdir( full_save_path ); end;
    filename = fullfile( full_save_path, base_filename );
    figure;
    pl.default();
    pl.x = x;
    pl.x_label = x_label;
    pl.y_lim = y_lim;
    pl.add_ribbon = true;
    pl.compare_series = true;
    pl.marker_size = 10;
    pl.set_colors = 'manual';
    pl.colors = { 'blue', 'red' };
    pl.order_by = { 'otherMinusNone', 'selfMinusBoth' };
    pl.shape = plot_shape;
    pl.plot( meaned, lines_are, panels_are );
    saveas( gcf, filename, 'epsc' );
    saveas( gcf, filename, 'png' );
    saveas( gcf, filename, 'fig' );
  end
end


end