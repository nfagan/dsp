function cont = dsp__load_container( directory, flag, selectors )

if ( nargin < 2 )
  flag = []; selectors = []; 
else
  assert( nargin == 3, 'Too few inputs' );
  assert( any(strcmp({'only', 'except'}, flag)), 'Unrecognized flag ''%s''' ...
    , flag );
  if ( ~iscell(selectors) ), selectors = { selectors }; end;
end

folders = dirstruct( directory, 'folders' );
assert( numel(folders) > 0, ...
  'No folders were found in the directory ''%s''', directory );
names = { folders(:).name };

if ( ~isempty(selectors) )
  selected_ind = cellfun( @(x) any(strcmp(selectors, x)), names );
  assert( sum(selected_ind) == numel(selectors), ['Could not find at least' ...
    , ' one of the selectors'] );
  if ( isequal(flag, 'only') )
    names = names( selected_ind );
  else names = names( ~selected_ind );
  end
end

cont = Container();

for i = 1:numel(names)
  fprintf( '\n - Processing folder ''%s'' (%d of %d)', names{i}, i, numel(names) );
  folder_path = fullfile( directory, names{i} );
  files = dirstruct( folder_path, '.mat' );
  assert( numel(files) > 0, 'No .mat files found in this directory' );
  for k = 1:numel(files)
    fprintf( '\n\t - Processing file %d of %d', k, numel(files) );
    current = load( fullfile(folder_path, files(k).name) );
    if ( isempty(current.one) ), continue; end;
    cont = append( cont, current.one );    
  end
end
fprintf( '\n' );


end