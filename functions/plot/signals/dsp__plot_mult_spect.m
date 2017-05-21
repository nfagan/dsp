function dsp__plot_mult_spect()

plot_day = '042517';

%   LINE SPEC
windows = { [0 300] };
plot_over_frequency = true;
line_limits = [ -.15 .07 ];

%   SPECTROGRAM SPEC
color_limits = [ -.15 .07 ];

%   BEHAV CORRELATIONS
time_freq_windows = { {[100 200], [45 65]}, {[200 300], [15 30]}, {[-50 50], [50 65]}, {[-50 50], [15 30]} };
plot_per_monk = false;
plot_resolution = 'per_day';

%   what to plot on each iteration
plot_spect = false;
plot_lines = false;
plot_bhv = true;

file_kinds = allcomb( { ...
    {'non_common_averaged'} ...
  , {'coherence__meaned'} ...
  , {'targacq', 'reward'} ...
} );

% measure_kinds = allcomb( { ...
%     {'pro_v_anti_drug', 'pro_v_anti', 'pro_minus_anti', 'pro_minus_anti_drug', 'pro_v_anti_oxy_minus_sal', 'pro_minus_anti_oxy_minus_sal'} ...
% } );

measure_kinds = allcomb( { ...
  {'pro_v_anti'} ...
} );

io = DSP_IO();
pl = ContainerPlotter();

base_load_path = fullfile( pathfor('ANALYSES'), '020317' );
bhv_load_path = pathfor( 'BEHAVIOR' );
base_save_path = fullfile( pathfor('PLOTS'), plot_day, 'signals' );
base_line_path = fullfile( pathfor('PLOTS'), plot_day, 'lines' );
base_bhv_path = fullfile( pathfor('PLOTS'), plot_day, 'behavior' );

if ( plot_bhv )
  orig_behav = io.load( bhv_load_path );
  orig_behav = dsp__remove_bad_days_and_blocks( orig_behav );
  orig_behav = SignalContainer( orig_behav.data, orig_behav.labels );
  load( fullfile(bhv_load_path, 'trial_fields') );
end

for i = 1:size(file_kinds, 1)
  ref_type = file_kinds{i, 1};
  measure_type = file_kinds{i, 2};
  epoch = file_kinds{i, 3};
  
  is_coherence = substr_exists( measure_type, 'coherence' );
  
  load_path = fullfile( base_load_path, ref_type, measure_type, epoch );
  save_path = fullfile( base_save_path, ref_type, measure_type, epoch );
  line_path = fullfile( base_line_path, ref_type, measure_type, epoch );
  bhv_path = fullfile( base_bhv_path, ref_type, measure_type, epoch );
  
  loaded = io.load( load_path );
  loaded = loaded.rm( {'errors', 'cued'} );
  
  bad_sites = dsp__identify_bad_sites( loaded, {'outcomes', 'administration', 'trialtypes'} );
  
  loaded = only_not_mult( loaded, bad_sites );
  if ( plot_bhv )
    fixed_behav = only_not_mult( orig_behav, bad_sites(:, 1) );
  end
  
  switch ( epoch )
    case 'reward'
      time = [ -500 500 ];
    case 'targacq'
      time = [ -150 500 ];
    case 'targon'
      time = [ -150 500 ];
    otherwise
      error( 'Unrecognized epoch ''%s''', epoch );
  end
  
  for k = 1:size(measure_kinds, 1)
    m_within = { 'outcomes', 'trialtypes', 'regions', 'drugs', 'administration' };
    current = loaded;
    
    %   identify the kind of measure
    measure_kind = measure_kinds{k, 1};
    is_pro = substr_exists( measure_kind, 'pro_' );
    is_drug = substr_exists( measure_kind, 'oxy' ) || substr_exists( measure_kind, 'drug' );
    is_pro_minus_anti = substr_exists( measure_kind, 'pro_minus_anti' );
    is_oxy_minus_sal = substr_exists( measure_kind, 'oxy_minus_sal' );
    if ( is_pro )
      current = current.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} );
    end
    if ( is_drug )
      current = current.subtract_across( 'post', 'pre', 'postMinusPre' );
    else
      current = current.rm( 'post' );
      current = current.collapse( 'drugs' );
    end
    if ( is_pro_minus_anti )
      current = current.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    end
    if ( is_oxy_minus_sal )
      current = current.do( m_within, @mean );
      current = current.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
    end
    meaned = current.do( m_within, @mean );
    full_save_path = fullfile( save_path, measure_kind );
    
    if ( is_coherence )
      spect_files_are = { 'trialtypes', 'drugs' };
      spect_panels_are = { 'outcomes', 'regions', 'monkeys', 'drugs' };
    else
      spect_files_are = { 'outcomes', 'trialtypes', 'drugs' };
      spect_panels_are = { 'outcomes', 'regions', 'monkeys', 'drugs' };
    end
    
    if ( plot_spect )    
      %   actual plotting
      dsp__plot_spect( meaned ...
        , spect_files_are ...
        , spect_panels_are ...
        , full_save_path ...
        , 'frequencies', [0 100] ...
        , 'time', time ...
        , 'clims', color_limits ...
      );  
    end
    
    if ( plot_lines )
  
      %   lines    
      full_line_path = fullfile( line_path, measure_kind );
      if ( exist(full_line_path, 'dir') ~= 7 ), mkdir(full_line_path); end;

      if ( is_drug && is_pro_minus_anti )
        lines_are = { 'drugs' };
        panels_are = { 'regions', 'outcomes' };
      end

      if ( is_drug && is_pro && ~is_pro_minus_anti )
        lines_are = { 'drugs' };
        panels_are = { 'outcomes', 'regions' };
      end

      if ( ~is_drug && is_pro )
        if ( is_coherence )
          lines_are = { 'outcomes' };
          panels_are = { 'regions' };
        else
          lines_are = { 'regions' };
          panels_are = { 'outcomes' };
        end
      end

      if ( plot_over_frequency )
        for j = 1:numel(windows)
          window = windows{j};
          filename = sprintf( '%d_%dms', window(1), window(2) );
          filename = fullfile( full_line_path, filename );
          meaned = current.time_mean( window );
          meaned = meaned.keep_within_freqs( [0 100] );
          figure;
          pl.default();
          pl.x = meaned.frequencies;
          pl.x_label = [];
          pl.y_lim = line_limits;
          pl.add_ribbon = true;
          pl.compare_series = true;
          pl.marker_size = 10;
          pl.set_colors = 'manual';
          pl.colors = { 'blue', 'red' };
          pl.order_by = { 'oxytocin', 'saline' };
          pl.shape = [];
          pl.plot( meaned, lines_are, panels_are );
          saveas( gcf, filename, 'epsc' );
          saveas( gcf, filename, 'png' );
          saveas( gcf, filename, 'fig' );
          close gcf;
        end
      else
        error( 'Cannot yet plot over time' );
        %   DO SOMETHING
      end
      
    end
    
    
    %   PLOT BEHAVIORAL CORRELATIONS
    
    if ( ~plot_bhv ), continue; end;
    
    behav = fixed_behav;
    
    if ( ~is_drug )
      behav = behav.rm( {'cued', 'post'} );
      behav = behav.collapse( 'drugs' );
    end
    
    if ( ~plot_per_monk )
      behav = behav.collapse( 'monkeys' );
      current = current.collapse( 'monkeys' );
    end
    
    if ( ~isequal(plot_resolution, 'per_site') )
      current = current.collapse( {'channels'} );
    end
    
    measures = Structure();
    pref = dsp__behavior_preference_index_within( behav ...
      , {'days', 'trialtypes', 'administration'} );
    pref = pref.replace( {'both:self'}, 'selfMinusBoth' );
    pref = pref.replace( {'other:none'}, 'otherMinusNone' );
    measures.rt = dsp__get_rt( behav, trial_fields );
    looks = dsp__get_combined_looking_measures( behav, trial_fields );
    measures.gaze = dsp__get_gaze_frequency( looks ...
      , {'days', 'outcomes', 'trialtypes', 'administration', 'looks_to', 'look_period'} );
    measures = get_flattened_gazes( measures ); 
    
    bhv_within = m_within( ~strcmp(m_within, 'regions') );
    bhv_within = [ bhv_within, {'days'} ];
    measures = measures.do( bhv_within, @mean );
    pref = pref.do( bhv_within, @mean );
    measures = measures.columnize();
    pref = pref.columnize();
    
    if ( is_pro )
      measures = measures.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} );
    end
    if ( is_drug )
      measures = measures.subtract_across( 'post', 'pre', 'postMinusPre' );
      pref = pref.subtract_across( 'post', 'pre', 'postMinusPre' );
    end
    if ( is_pro_minus_anti )
      measures = measures.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      pref = pref.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    end
    
    meaned = current.do( [m_within, {'days', 'channels'}], @mean );
    to_collapse = { 'blocks', 'trials', 'sessions', 'recipients', 'magnitudes' };
    measures = measures.collapse( to_collapse );
    pref = pref.collapse( to_collapse );
    
    pref = meaned.match( pref );
    measures = measures.each( @(x) meaned.match(x) );
    measures.pref = pref;
    
    meaned = add_sites( meaned );
    
    [mult_regions, ~, regs] = meaned.enumerate( {'regions', 'sites'} );
    rebuilt = mult_regions{1};
    days = rebuilt('days');
    rebuilt_measures = measures;
    rebuilt_measures = rebuilt_measures.add_field( 'regions', regs{1, 1} );
    rebuilt_measures = rebuilt_measures.add_field( 'sites', regs{1, 2} );
    original_rebuilt = rebuilt_measures;
    rebuilt_measures = rebuilt_measures.only( days );
    for j = 2:numel(mult_regions)
      days = mult_regions{j}('days');
      for h = 1:measures.nfields()
        current = original_rebuilt{h}.only( days );
        current( 'regions' ) = regs{j, 1};
        current( 'sites' ) = regs{j, 2};
        rebuilt_measures{h} = rebuilt_measures{h}.append( current );
      end
      rebuilt = rebuilt.append( mult_regions{j} );
    end
    additional_fields = setdiff( rebuilt.field_names(), rebuilt_measures{1}.field_names() );
    rebuilt = rebuilt.rm_fields( additional_fields );
    
    plt_combs = allcomb( {time_freq_windows(:)', rebuilt_measures.fields()'} );
    
    for j = 1:size( plt_combs, 1 )
      full_meaned = rebuilt;
      current_window = plt_combs{j, 1};
      measure_type = plt_combs{j, 2};
      full_meaned = full_meaned.time_mean( current_window{1} );
      full_meaned = full_meaned.freq_mean( current_window{2} );
      behav_measure = rebuilt_measures.(measure_type);
      figure;
      base_filename = sprintf( '%d_to_%dms_%d_to_%d_hz' ...
        , current_window{1}(1), current_window{1}(2) ...
        , current_window{2}(1), current_window{2}(2) );
      pl.default();
      pl.scatter( full_meaned, behav_measure, {'outcomes'}, {'regions', 'monkeys', 'drugs', 'outcomes'} );
      formats = { 'epsc', 'svg', 'png' };
      for h = 1:numel( formats )
        full_bhv_path = fullfile( bhv_path, measure_kind, plot_resolution, measure_type, formats{h} );
        if ( exist(full_bhv_path, 'dir') ~= 7 ), mkdir(full_bhv_path); end;
        full_filename = fullfile( full_bhv_path, [base_filename '.' formats{h}] );
        saveas( gcf, full_filename, formats{h} );
      end
      close gcf;
    end
            
  end
end

end

function tf = substr_exists( str, substr )

tf = ~isempty( strfind(str, substr) );

end

function obj = only_not_mult( obj, mult )

for i = 1:size(mult, 1)
  obj = obj.only_not( mult(i, :) );
end

end

function obj = get_flattened_gazes( obj )

gaze = obj.gaze;
[objs, ~, c] = gaze.enumerate( {'looks_to', 'look_period'} );
for i = 1:numel(objs)
  row = strjoin( c(i, :), '_' );
  obj.(row) = objs{i}.rm_fields( {'looks_to', 'look_period'} );
end

obj = obj.rm_fields( 'gaze' );

end

function obj = add_sites( obj )

if ( obj.contains_fields('sites') )
  obj = obj.rm_fields( 'sites' );
end

obj = obj.add_field( 'sites' );
inds = obj.get_indices( {'days', 'channels', 'regions'} );
for i = 1:numel(inds)
  obj( 'sites', inds{i} ) = sprintf( 'site__%d', i );
end


end
 
