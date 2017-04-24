%%  load behavioral data / configure save destination

io = DSP_IO();
load_path = pathfor( 'BEHAVIOR' );
original_behav = io.load( load_path );
load( fullfile(load_path, 'trial_fields.mat') );

save_path = fullfile( pathfor('PLOTS'), '042017', 'behavior', 'test' );
if ( exist(save_path, 'dir') ~= 7 ), mkdir( save_path ); end;

%%  only include block 1 and block 2 from non injection days

%   Only include PRE data. For non injection days ('unspecified'), only
%   keep blocks 1 and 2, and set these to PRE

behav = original_behav;
behav = dsp__remove_bad_days_and_blocks( behav );
unspc = behav.only( 'unspecified' );
behav = behav.rm( 'unspecified' );
unspc = unspc.only( {'block__1', 'block__2'} );
unspc( 'administration' ) = 'pre';
behav = behav.append( unspc );
behav = behav.only( {'pre'} );
behav = behav.rm( 'errors' );

%%  only keep pre, choice trials; remove errors

behav = behav.only( {'pre'} );
behav = behav.rm( 'errors' );

%%  plot

dsp__plot_behavior_gaze( behav, trial_fields, save_path );
dsp__plot_behavior_gaze_frequency( behav, trial_fields, save_path );
dsp__plot_behavior_rt( behav, trial_fields, save_path );
dsp__plot_behavior_pref_index( behav, save_path );