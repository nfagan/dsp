function dsp__create_and_save_shuffled_labels()

io = DSP_IO();

combs = allcomb( { ...
    {'coherence', 'normalized_power'} ...
  , {'common_averaged'} ...
});

N_REPS = 100;
epoch = 'targacq';

base_save_path = fullfile( pathfor('ANALYSES'), '020317', 'shuffled', 'labels_no_errors' );
base_load_path = fullfile( pathfor('ANALYSES'), '020317' );

for i = 1:size( combs, 1 )
  
  measure = combs{i, 1};
  method = combs{i, 2};
  
  full_load_path = fullfile( base_load_path, method, measure, epoch );
  full_save_path = fullfile( base_save_path, method, measure );
  
  if ( exist(full_save_path, 'dir') ~= 7 ), mkdir(full_save_path); end;
  
  if ( isequal(measure, 'coherence') )
    shuffle_within = { 'sites', 'administration', 'trialtypes' };
  else shuffle_within = { 'channels', 'administration', 'trialtypes' };
  end
  
  days = io.get_days( full_load_path );
  for k = 1:numel(days)
    signal_measure = io.load( full_load_path, 'only', days{k} );
    signal_measure = signal_measure.rm( {'errors', 'cued'} );
    labs_and_orders = dsp__get_shuffled_labels_and_orders( signal_measure ...
      , shuffle_within, N_REPS );
    io.save( labs_and_orders, full_save_path );
  end
  
end