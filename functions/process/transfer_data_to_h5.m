function transfer_data_to_h5()

% measures_h5 = fullfile( pathfor('DATABASE'), 'measures.h5' );
measures_h5 = 'E:\SIGNALS\dictator\database\measures.h5';
% signals_h5 = fullfile( pathfor('DATABASE'), 'signals.h5' );

io_old = dsp2.io.DSP_IO();

io = dsp2.io.dsp_h5();
io.CHUNK_SIZE = [ 1e3, 1e3, 1e3 ];

if ( ~io.file_exists(measures_h5) )
  io.create( measures_h5 );
else
  io.h5_file = measures_h5;
end

conf = dsp2.config.load();
base_loadpath = conf.PATHS.analysis_subfolder;
ref_type = conf.SIGNALS.reference_type;
% measures = { 'coherence', 'normalized_power', 'raw_power' };
measures = { 'raw_power' };

for i = 1:numel( measures )
  fprintf( '\n Processing measure ''%s'' (%d of %d)', measures{i}, i, numel(measures) );
  
  base_measurepath = fullfile( base_loadpath, ref_type, measures{i} );
  epochs = dsp2.util.general.dirstruct( base_measurepath, 'folders' );
  epochs = { epochs(:).name };
  for k = 1:numel(epochs)
    fprintf( '\n\t Processing epoch ''%s'' (%d of %d)', epochs{k}, k, numel(epochs) );
    
    epoch_path = fullfile( base_measurepath, epochs{k} );
    days = io_old.get_days( epoch_path );
    
    full_savepath = io.fullfile( 'Measures/Signals', ref_type, measures{i}, 'complete', epochs{k} );
    io.create_group( full_savepath );
    
    for j = 1:numel(days)
      
      loaded = io_old.load( epoch_path, 'only', days{j} );
      loaded = dsp2.process.format.fix_sites( loaded );
      loaded.params = conf.SIGNALS.signal_container_params;
      io.add( loaded, full_savepath );
      clear loaded;
      
    end
    
  end
end