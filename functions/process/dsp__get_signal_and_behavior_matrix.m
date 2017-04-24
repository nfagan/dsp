function mat = dsp__get_signal_and_behavior_matrix(signal_measure_path, behav_measure_path, varargin)

io = DSP_IO();

params = struct( ...
    'behav_measure', 'reaction_time' ...
  , 'selectors', {{'hitch', 'oxytocin'}} ...
  , 'voltage_range', .3 ...
  , 'std_range', 2 ...
  , 'time_freq', {{[], [0 100]}} ...
  );
params = parsestruct( params, varargin );
desired_behav_measure = params.behav_measure;

selectors = { 'hitch', 'oxytocin' };

if ( ~isempty(params.selectors) )
  measure = io.load( signal_measure_path, 'only', selectors );
  behav = io.load( behav_measure_path, 'only', selectors );
else
  measure = io.load( signal_measure_path );
  behav = io.load( behav_measure_path );
end
load( fullfile(behav_measure_path, 'trial_fields.mat') );
behav = SignalContainer( behav.data, behav.labels );
behav.data = behav.data(:, strcmp(trial_fields, desired_behav_measure));
nan_ind = isnan( behav.data );
behav = behav.keep( ~nan_ind );

meaned = measure;
meaned = meaned.keep_within_range( params.voltage_range );
meaned = meaned.time_freq_mean( params.time_freq{:} );
meaned = meaned.do_per( {'regions', 'monkeys', 'drugs', 'outcomes'} ...
  , @dsp__std_threshold, params.std_range );
if ( any(strcmp(meaned.field_names(), 'sites')) )
  meaned = meaned.mean_across( {'sites', 'channels', 'blocks', 'trials'} );
else meaned = meaned.mean_across( {'channels', 'blocks', 'trials'} );
end

behav = behav.mean_across( {'trials', 'blocks'} );

mat = dsp__get_matrix( meaned, behav );

end


