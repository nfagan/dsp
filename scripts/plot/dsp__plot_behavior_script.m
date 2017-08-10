%%  load behavioral data / configure save destination

io = dsp2.io.get_dsp_h5();
pathstr = dsp2.io.get_path( 'behavior' );
behav = io.read( pathstr );
behav = dsp__remove_bad_days_and_blocks( behav );
trial_fields = io.read( io.fullfile(pathstr, 'Key') );

day = '060217';
subfolder = 'behavior\per_drug';

save_path = fullfile( pathfor('PLOTS'), day, subfolder );
if ( exist(save_path, 'dir') ~= 7 ), mkdir( save_path ); end;

%%  only include block 1 and block 2 from non injection days

%   Only include PRE data. For non injection days ('unspecified'), only
%   keep blocks 1 and 2, and set these to PRE

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

%%  only keep oxytocin and saline; remove errors

behav = behav.only( {'oxytocin', 'saline'} );
behav = behav.rm( {'errors', 'cued', 'pre'} );

%%  collapse things

behav = behav.collapse( {'administration', 'monkeys'} );

%%  plot

dsp__plot_behavior_gaze( behav, trial_fields, save_path );
dsp__plot_behavior_gaze_frequency( behav, trial_fields, save_path );
dsp__plot_behavior_rt( behav, trial_fields, save_path );
dsp__plot_behavior_pref_index( behav, save_path );