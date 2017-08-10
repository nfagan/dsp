function dsp__fix_block_numbers()

%%  fix measures
io = dsp2.io.get_dsp_h5();

% measures = { 'normalized_power', 'raw_power' };
measures = { 'coherence' };
types = { 'complete', 'meaned' };

c = dsp2.util.general.allcomb( {measures, types} );

label_sets = { 'indices', 'categories', 'labels' };

for i = 1:size(c, 1)
  fprintf( '\n Processing combination %d of %d', i, size(c, 1) );
  
  row = c(i, :);
  pathstr = dsp2.io.get_signal_measure_path( row{:} );
  if ( ~io.is_group(pathstr) ), continue; end;
  epochs = io.get_component_group_names( pathstr );
  for k = 1:numel(epochs)
    full_path = io.fullfile( pathstr, epochs{k} );
    labs = io.read_labels_( full_path );
    data = zeros( shape(labs, 1), 1 );
    cont = Container( data, labs );
    cont = cont.do( 'days', @dsp2.process.format.fix_block_number );
    labs = cont.labels;
    full_labelsets = cellfun( @(x) io.fullfile(full_path, x), label_sets, 'un', false );
    cellfun( @(x) io.unlink(x), full_labelsets );
    io.write_labels_( labs, full_path, 1 );
  end
end

return;

%%  fix signals

types = { 'complete' };

c = dsp2.util.general.allcomb( {types} );

for i = 1:size(c, 1)
  
  row = c(i, :);
  pathstr = io.fullfile( 'Signals/non_common_averaged', row{:} );
  if ( ~io.is_group(pathstr) ), continue; end;
  epochs = io.get_component_group_names( pathstr );
  for k = 1:numel(epochs)
    full_path = io.fullfile( pathstr, epochs{k} );
    labs = io.read_labels_( full_path );
    data = zeros( shape(labs, 1), 1 );
    cont = Container( data, labs );
    cont = cont.do( 'days', @dsp2.process.format.fix_block_number );
    labs = cont.labels;
    full_labelsets = cellfun( @(x) io.fullfile(full_path, x), label_sets, 'un', false );
    cellfun( @(x) io.unlink(x), full_labelsets );
    io.write_labels_( labs, full_path, 1 );
  end  
end