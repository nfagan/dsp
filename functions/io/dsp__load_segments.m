function obj = dsp__load_segments( directory, epochs )

if ( nargin < 2 ), epochs = []; end

mats = dirstruct( directory, '.mat' );
assert( numel(mats) > 0, 'No .mat files found in this directory' );
names = { mats(:).name };
data_ind = 1;

if ( ~isempty(epochs) )
  if ( ~iscell(epochs) ), epochs = { epochs }; end;
  assert( iscellstr(epochs), 'Specify epochs as a cell array of strings, or char' );
  store_targets = {};
  for i = 1:numel(epochs)
    targets = cellfun( @(x) ~isempty(strfind(x, epochs{i})), names );
    assert( any(targets), 'The epoch ''%s'' does not exist', epochs{i} );
    store_targets = [store_targets names(targets) ];
  end
  names = store_targets;
end

obj = Structure();

while ( ~isempty(names) )
  fprintf( '\n ! dsp__load_segments: %d remaining', numel(names) );
  current = names{data_ind};
  underscores = strfind( current, '__' );
  if ( isempty(underscores) )
    error( 'Attempted to load files not generated from dsp__save_segments' );
  end
  if ( numel(underscores) == 1 ), data_ind = data_ind + 1; continue; end;
  data_ind = 1;
  epoch = current( 1:underscores(1)-1 );
  current_obj = Container();
  current_props = [ epoch '__PROPS.mat' ];
  prop_ind = strcmp( names, current_props );
  names(prop_ind) = [];
  segment_index = cellfun( @(x) ~isempty(strfind(x, epoch)), names );
  segments = names(segment_index);
  names(segment_index) = [];
  load( fullfile(directory, current_props) );
  %   make sure we load the segments back in order
  ind = get_sorted_index( segments );
  segments = segments( ind );
  for i = 1:numel(segments)
    load( fullfile(directory, segments{i}) );
    current_obj = append( current_obj, extr );
  end
  if ( ~isnan(props.time) && ~isnan(props.fs) )
    current_obj = to_data_object( current_obj );
    current_obj = SignalObject( current_obj, props.fs, props.time );
  end
  obj.(epoch) = current_obj;
end

end

function ind = get_sorted_index( segments )

nums = zeros( size(segments) );

for i = 1:numel(segments)
  underscores = strfind( segments{i}, '__' );
  nums(i) = str2double( segments{i}(underscores(1)+2:underscores(2)-1) );
end

[~, ind] = sort( nums );

end