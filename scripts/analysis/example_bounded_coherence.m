%% load in

current_signals = dsp__post_process( signals.rwdOn );
current_signals = dsp__ref_subtract_within_day( current_signals );
current_signals = current_signals.remove( 'errors' );
ids = dsp__get_trial_ids( current_signals );
current_signals = filter( current_signals );

%%  COHERENCE
[measures.multitaper, f, measure_ids] = analysis__coherence( current_signals ...
  , 'subtractReference', false ...
  , 'takeMean', false ...
  , 'method', 'multitaper' ...
  , 'ids', ids ...
);

%%  COHERENCE

m.coherence = dsp__analysis__coherence_all( current_signals, 'ids', ids );
m.normpower = dsp__analysis__normalized_power( reward, magcue, 'ids', ids );

%%

[bounded, n_excl, n_tot, empties] = ...
  dsp__bound_measure( measure, measure_ids, current_signals, ids, .3 ...
  , 'selectors', [] );

bounded = dsp__mean_across_trials( bounded );

disp( sum(n_excl) / sum(n_tot) );

%%

transformed = bounded;

transformed = transformed.meanacross( 'channels' );
transformed = transformed.subtract_across( 'post', 'pre', 'postMinusPre' );
% transformed = transformed.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
% transformed = append( transformed.subtract_across('self','both','sMb') ...
%   , transformed.subtract_across('other','none','oMn') );


%%

monk = 'kuro';
drug = 'saline';
outcome = 'other';

selected = transformed.only( {outcome,monk,'choice',drug} );
plot__spectrogram( selected, 'freqs', f', 'fromTo', [], 'freqLimits', [0 100], 'clims', [-.04 0.04]  )