function dsp__plot_coherence_and_power_over_days()

io = DSP_IO();

combs = allcomb( {...
    {'common_averaged', 'non_common_averaged'} ...
  , {'normalized_power', 'coherence'} ...  
  , {'saline', 'oxytocin'} ...
  , {'hitch', 'kuro'} ...
});
epoch = 'targacq';
base_path = 'E:\nick_data\ANALYSES\020317\';
base_plot_path = 'E:\nick_data\PLOTS\021317';

for i = 1:size( combs, 1 )
  meth =    combs{ i, 1 };
  kind =    combs{ i, 2 };
  drug =    combs{ i, 3 };
  monk =    combs{ i, 4 };
  
  load_path = fullfile( base_path, meth, kind, epoch );
  plot_save_path = fullfile( base_plot_path, meth, kind, epoch );
  
  measure = io.load( load_path, 'only', {monk, drug} );
  measure = measure.update_label_sparsity();
  
  %   ADD PERCENT OF TRIALS PER DAY
  
  if ( isequal(kind, 'coherence') )
    percent_cats = { 'administration', 'sites', 'regions' };
  else percent_cats = { 'administration', 'regions' };
  end
  measure = measure.do_per( percent_cats, @dsp__add_percent_of_trials_per_day );
  measure = dsp__percent_in_range( measure, [0 1] );
  
  %   END PERCENT OF TRIALS PER DAY
  
  measure = measure.remove( {'errors', 'cued', 'unspecified'} );
  if ( isempty(measure) ), continue; end;
  if ( isequal(kind, 'coherence') )
    measure = measure.collapse( 'regions' );
  end
  measure = measure.keep_within_range( .3 );
  if ( isempty(measure) ), continue; end;
  meaned = measure.time_freq_mean( [], [0 100] );
  good_trials = dsp__std_threshold_index( meaned, {'regions', 'drugs', 'outcomes'}, 2 );
  measure = measure.keep( good_trials );
  measure = measure.mean_within( ...
    {'administration', 'epochs', 'regions', 'monkeys', 'drugs', 'outcomes', 'trialtypes'} );
  measure = measure.subtract_across( 'post', 'pre', 'post_minus_pre' );
  
  %   plot self+both+other+none in one panel
  
  inds = measure.get_indices( setdiff(measure.field_names(), 'outcomes') );
  generate_plot( measure, inds, 'outcomes', plot_save_path, [2 2] );
  
  %   plot separately
  
  inds = measure.get_indices( measure.field_names() );
  generate_plot( measure, inds, [], plot_save_path, [] );
  
end

end

function generate_plot( measure, inds, within, plot_save_path, shape )

for k = 1:numel(inds)
  extr =  measure.keep( inds{k} );
  monk =  char( extr('monkeys') );
  admin = char( extr('administration') );
  drug =  char( extr('drugs') );
  out =   strjoin( extr('outcomes'), '_' );
  reg =   char( extr('regions') );
  extr.spectrogram( within ...
    , 'frequencies', [0 100] ...
    , 'clims', [] ...
    , 'shape', shape ...
    , 'fullScreen', true ...
  );
  full_save_path = fullfile( plot_save_path, monk, reg, drug, admin );
  if ( exist(full_save_path, 'dir') ~= 7 ), mkdir(full_save_path); end;
  file_name = fullfile( full_save_path, out );
  saveas( gcf, file_name, 'epsc' );
  saveas( gcf, file_name, 'png' );
end

end

