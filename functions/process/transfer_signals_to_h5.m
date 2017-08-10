function transfer_signals_to_h5()

measures_h5 = 'E:\SIGNALS\dictator\database\measures.h5';

io_old = dsp2.io.DSP_IO();

io = dsp2.io.dsp_h5();
io.CHUNK_SIZE = [ 1e3, 2.5e3, Inf ];

if ( ~io.file_exists(measures_h5) )
  io.create( measures_h5 );
else
  io.h5_file = measures_h5;
end

conf = dsp2.config.load();
base_loadpath = conf.PATHS.pre_processed_signals;
ref_type = conf.SIGNALS.reference_type;

base_signalpath = fullfile( base_loadpath, ref_type );
epochs = dsp2.util.general.dirstruct( base_signalpath, 'folders' );
epochs = { epochs(:).name };
for k = 1:numel(epochs)
  fprintf( '\n\t Processing epoch ''%s'' (%d of %d)', epochs{k}, k, numel(epochs) );

  epoch_path = fullfile( base_signalpath, epochs{k} );

  full_savepath = io.fullfile( 'Signals', ref_type, 'complete', epochs{k} );
  
  if ( ~io.is_group(full_savepath) )
    io.create_group( full_savepath );
  end
  
  loaded = io_old.load( epoch_path );
  loaded = loaded.update_range();
%   loaded = dsp2.process.format.fix_block_number( loaded );
  io.add( loaded, full_savepath );
%   clear loaded;
  
end