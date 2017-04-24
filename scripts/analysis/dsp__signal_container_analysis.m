%% load in
signals = dsp__get_signals( db );
%%  GET CURRENT SIGNALS

current_signals = dsp__ref_subtract_within_day( signals.rwdOn );
current_signals = remove( current_signals, 'errors' );
current_signals = filter( current_signals );

%%  GET CURRENT SIGNALS - STRUCT

signals = signals.remove( 'errors' );
signals = signals.each( @dsp__ref_subtract_within_day );
ids = dsp__get_trial_ids( signals{2} );
signals.reward.trial_ids = ids;
signals.magcue.trial_ids = ids;
signals = signals.filter();

%%  ANALYSIS

m.coherence = dsp__analysis__coherence_all( signals.reward );
m.normpower = dsp__analysis__norm_power_all( signals.reward, signals.magcue );

%%  BOUND

measure = m.normpower;

bounds = SignalContainer.get_in_bounds_trial_ids( current_signals{1}, .3 );
bounded = retain_by_id( measure, bounds );

fprintf( '\nRetained:\n%f\n\n', (shape(bounded, 1) / shape(measure, 1)) );

%%  CREATE TRIAL SET
tic;
set = create_trial_sets( bounded, {'monkeys','drugs','trialtypes','administration','outcomes','days', 'regions'} );
toc;
tic;
meaned = mean_across_trials( set );
toc;

%%  PLOT

base_path = fullfile( 'E:\nick_data\PLOTS\020217\hitch', 'norm_power', 'fixed_limits' );

selected = meaned.only( {'choice', 'hitch'} );
selected = selected.remove( 'unspecified' );
inds = get_indices( selected, {'outcomes', 'administration', 'drugs', 'regions'} );

for i = 1:numel(inds)
  extr = selected( inds{i} );
  days = unique( extr('days') );
  region = char( extr('regions') );
  outcome = char( extr('outcomes') );
  drug = char( extr('drugs') );
  admin = char( extr('administration') );
  
  save_path = fullfile( base_path, outcome, region, drug(1:3), admin );
  
  for k = 1:numel(days)
    to_plot = selected.only( days{k} );
    plot__spectrogram( to_plot ...
      , 'freqs', to_plot.frequencies' ...
      , 'clims', [.05 .5] ...
      , 'freqLimits', [0 100] ...
      , 'title', days{k} ...
    );
    save_str = strjoin( to_plot.labels.labels, '_' );
    save_str = fullfile( save_path, save_str );
    saveas( gcf, save_str, 'epsc' );
    saveas( gcf, save_str, 'png' );
    close gcf;
  end  
end
