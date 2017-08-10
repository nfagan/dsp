%%  fix signals
io = dsp2.io.get_dsp_h5();
basepath = dsp2.io.get_path( 'signals', 'complete' );
epochs = io.get_component_group_names( basepath );
to_unlink = { 'labels', 'categories', 'indices' };
for i = 1:numel(epochs)
  fprintf( '\n Processing ''%s'' (%d of %d)', epochs{i}, i, numel(epochs) );
  fullpath = io.fullfile( basepath, epochs{i} );
  labels = io.read_labels_( fullpath );
  nrows = labels.shape(1);
  cont = Container( zeros(nrows, 1), labels );
  cont = dsp2.process.format.fix_sites( cont );
  labels = cont.labels;
  cellfun( @(x) io.unlink(io.fullfile(fullpath, x)), to_unlink );
  io.write_labels_( labels, fullpath, 1 );
end

%%  fix signals -- props
io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();
basepath = dsp2.io.get_path( 'signals', 'complete' );
epochs = io.get_component_group_names( basepath );
for i = 1:numel(epochs)
  fprintf( '\n Processing ''%s'' (%d of %d)', epochs{i}, i, numel(epochs) );
  fullpath = io.fullfile( basepath, epochs{i}, 'props' );
  props = io.read( fullpath );
  props.params = conf.SIGNALS.signal_container_params;
  io.write( props, fullpath );
%   io.write_labels_( props, fullpath );
end

dsp2.io.add_processed_signals();

%%  fix measures
io = dsp2.io.get_dsp_h5();
measures = { 'normalized_power' };
for k = 1:numel(measures)
  fprintf( '\n Processing ''%s'' (%d of %d)', measures{k}, k, numel(measures) );
  measure = measures{k};
  basepath = dsp2.io.get_path( 'measures', measure, 'complete' );
  epochs = io.get_component_group_names( basepath );
  to_unlink = { 'labels', 'categories', 'indices' };
  for i = 1:numel(epochs)
    fprintf( '\n\t Processing ''%s'' (%d of %d)', epochs{i}, i, numel(epochs) );
    fullpath = io.fullfile( basepath, epochs{i} );
    labels = io.read_labels_( fullpath );
    orig_labels.(epochs{i}) = labels;
    nrows = labels.shape(1);
    cont = Container( zeros(nrows, 1), labels );
    cont = dsp2.process.format.fix_sites( cont );
    labels = cont.labels;
    cellfun( @(x) io.unlink(io.fullfile(fullpath, x)), to_unlink );
    io.write_labels_( labels, fullpath, 1 );
  end
end


