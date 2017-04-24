function dsp__save_segments( obj, directory, segment_size )

try
  orig = cd; cd( directory ); cd(orig);
catch err
  error( err.message );
end

if ( ~isa(obj, 'Structure') )
  assert( isa(obj, 'DataObjectStruct'), ['Input can either be a Structure or' ...
    , ' DataObjectStruct'] );
  obj = Structure( obj.objects );
end

directory = fullfile( directory, 'segments' );
if ( exist(directory, 'dir') ~= 7  ), mkdir( directory ); end;

fs = fields( obj );

for i = 1:numel(fs)
  fprintf( '\n ! dsp__save_segments: Saving %d of %d', i, numel(fs) );
  one = obj.(fs{i});
  if ( ~isa(one, 'Container') )
    assert( isa(one, 'SignalObject'), ['Each field of the input struct must be' ...
      , ' a SignalObject'] );
    props.time = one.time;
    props.fs = one.fs;
    one = Container.create_from( one );
  else
    props.time = NaN; props.fs = NaN;
  end
  
  %   save lightweight properties first
  filename = fullfile( directory, [fs{i} '__PROPS.mat'] );
  if ( exist(filename, 'file') == 2 )
    in = input( sprintf(['\n\nWARNING: Files already exist in this segment folder.' ...
      , '\nDo you wish to overwrite them? (y/n)'], filename), 's' );
    if ( isequal(lower(in), 'n') ), return; end;
  end
  save( filename, 'props' );
  start = 1;
  stop = start + segment_size - 1;
  id = 1;
  break_next = false;
  while ( true )
    extr = one(start:stop);
    filename = fullfile( directory, sprintf('%s__%d__DATA.mat', fs{i}, id) );
    save( filename, 'extr' );
    if ( break_next ), break; end;
    id = id + 1;
    start = stop + 1;
    stop = start + segment_size - 1;
    if ( stop >= shape(one,1) )
      stop = shape(one,1);
      break_next = true;
    end
  end
end

end

function str = get__char(number)

repeats = number / 26;


end