function dsp__add_sites_to_h5( set_type, varargin )

to_unlink = { 'labels', 'indices', 'categories' };

c = dsp2.util.general.allcomb( varargin );

io = dsp2.io.get_dsp_h5();

for i = 1:size(c, 1)
  fprintf( '\n Processing %d of %d', i, size(c, 1) );
  
  row = c(i, :);
  
  pathstr = dsp2.io.get_path( set_type, row{:} );
  
  if ( ~io.is_group(pathstr) ), continue; end;
  
  epochs = io.get_component_group_names( pathstr );
  
  for k = 1:numel(epochs)
    fprintf( '\n\t Processing ''%s'' (%d of %d)', epochs{k}, k, numel(epochs) );
    epoch_path = io.fullfile( pathstr, epochs{k} );
    labs = io.read_labels_( epoch_path );
    if ( labs.contains_categories('sites') )
      fprintf( '\n Sites exist already ...' );
      continue;
    end
    new_labs = SparseLabels();
    days = labs.get_fields( 'days' );
    for j = 1:numel(days)      
      extr = labs.only( days{j} );
      inds = extr.get_indices( {'channels', 'regions'} );
      extr = extr.add_field( 'sites' );
      stp = 1;
      for h = 1:numel(inds)
        extr = extr.set_field( 'sites', sprintf('site__%d', stp), inds{h} );
        stp = stp + 1;
      end
      new_labs = new_labs.append( extr );
    end
    try
      to_unlink_ = cellfun( @(x) io.fullfile(epoch_path, x), to_unlink, 'un', false );
      cellfun( @(x) io.unlink(x), to_unlink_ );
      io.write_labels_( new_labs, epoch_path );
    catch
      d = 10;
    end
  end
  
end