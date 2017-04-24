function dsp__plot_signal_and_behavior_measures()

io = DSP_IO();

combs = allcomb( {...
    {'common_averaged'} ...
  , {'coherence'} ...
  , {'reward', 'targacq'} ...
  , {'hitch', 'kuro'} ...
  , {'saline', 'oxytocin'}
});

base_signal_path = fullfile( pathfor('ANALYSES'), '020317' );
plot_save_path = fullfile( pathfor('PLOTS'), '021417', 'behavior', 'site_by_site' );
behav_path = pathfor( 'BEHAVIOR' );

behav_measures = { 'preference_index', 'reaction_time', 'earlyLookCount' ...
  , 'earlyBottleLookCount' };
all_behavior = io.load( behav_path );
pref_index = dsp__behavior_preference_index_within( all_behavior ...
  , {'days', 'monkeys', 'drugs', 'administration', 'trialtypes'} );
pref_index = pref_index.remove( {'errors', 'cued', 'unspecified'} );
pref_index = pref_index.replace( 'both:self', 'bothMinusSelf' );
pref_index = pref_index.replace( 'other:none', 'otherMinusNone' );
pref_index = SignalContainer( pref_index.data, pref_index.labels );
pref_index.mean_within( {'outcomes', 'administration', 'monkeys', 'drugs', 'days'} );

store_correlations = Container();

for i = 1:size( combs, 1 )
  fprintf( '\n\n\nProcessing %d of %d\n\n\n', i, size(combs, 1) );
  meth = combs{i, 1};
  measure = combs{i, 2};
  epoch = combs{i, 3};
  monk = combs{i, 4};
  drug = combs{i, 5};
  
  signal_path = fullfile( base_signal_path, meth, measure, epoch );
  selectors = { monk, drug };
  signal_measure = dsp__get_measure_with_behavior( signal_path, selectors );

  meaned = signal_measure;
  meaned = meaned.remove( {'errors', 'cued', 'unspecified'} );
  meaned = meaned.keep_within_range( .3 );
  meaned = meaned.time_freq_mean( [], [0 100] );
  meaned = meaned.do_per( {'monkeys', 'regions', 'drugs', 'outcomes'} ...
    , @dsp__std_threshold, 2 );
  meaned = meaned.mean_within( ...
    {'outcomes', 'administration', 'monkeys', 'drugs', 'days', 'sites'} );
  %   subtraction
  meaned = meaned.do_per( {'days', 'sites', 'administration'}, @dsp__require_outcomes );
  subbed = meaned.subtract_across_mult( {'both', 'self', 'bothMinusSelf'} ...
    , {'other', 'none', 'otherMinusNone'} );
  for k = 1:numel(behav_measures)
    if ( ~isequal(behav_measures{k}, 'preference_index') )
      behav = Container( subbed.trial_stats.(behav_measures{k}), subbed.labels );
    else
      sites = unique( subbed('sites') );
      behav = pref_index.collapse_uniform();
      behav = behav.collapse( {'sessions', 'blocks', 'recipients'} );
      rebuilt_measure = Container();
      rebuilt_behav = Container();
      for j = 1:numel(sites)
        extr = subbed.only( sites{j} );
        extr_behav = extr.match( behav );
        rebuilt_measure = rebuilt_measure.append( extr );
        rebuilt_behav = rebuilt_behav.append( extr_behav );
      end
      rebuilt_behav.labels = rebuilt_measure.labels;
      subbed = rebuilt_measure;
      behav = rebuilt_behav;
    end
    
    nans = isnan( behav.data );
    subbed = subbed.keep( ~nans );
    behav = behav.keep( ~nans );
    
    %   correlate
    
    corred = dsp__correlate_within( subbed, behav ...
      , {'outcomes', 'administration', 'drugs', 'monkeys', 'regions'} );
    corred = corred.add_field( 'methods', meth );
    corred = corred.add_field( 'signal_measures', measure );
    corred = corred.add_field( 'behavioral_measures', behav_measures{k} );
    corred('epochs') = epoch;
    store_correlations = store_correlations.append( corred );
    
    %   scatter
    
    drugs = unique( behav('drugs') );
    for j = 1:numel(drugs)
      subbed.scatter( behav, {'outcomes', 'administration'} ...
        , 'yLabel', ['Difference in ' strrep(behav_measures{k}, '_', ' ')] ...
        , 'xLabel', 'Difference in Coherence' ...
        , 'shape', [2 2] ...
      );
      full_plot_folder = fullfile( plot_save_path, meth, measure, epoch, monk, drugs{j} );
      if ( exist(full_plot_folder, 'dir') ~= 7 ), mkdir( full_plot_folder ); end;
      filename = fullfile( full_plot_folder, behav_measures{k} );
      saveas( gcf, filename, 'png' );
      saveas( gcf, filename, 'epsc' );
    end
  end
end

end




