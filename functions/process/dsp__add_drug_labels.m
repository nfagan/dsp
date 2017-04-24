function obj = dsp__add_drug_labels( obj, folder )

map = struct( ...
  'sal', 'saline', ...
  'ot', 'oxytocin', ...
  'oxy', 'oxytocin', ...
  'unspecified', 'unspecified' ...
);

if ( nargin < 2 ), folder = fullfile( pathfor('RAW_SIGNALS'), '011217\processed' ); end;
folders = remDir( dirstruct(folder, 'folders') );

names = { folders(:).name };

for i = 1:numel( names )
  name = names{i};
  underscores = strfind( name, '_' );
  assert( numel(underscores) >= 2, ...
    'Too few underscores in the foldername ''%s''', name );
  date = name( underscores(1)+1:underscores(2)-1 );
  drug = name( underscores(2)+1:end );
  
  drug_fields = fieldnames( map );
  correct_drug_index = cellfun( @(x) ~isempty(strfind(lower(drug), x)), drug_fields );
  assert( any(correct_drug_index), 'Invalid drug format for folder ''%s''', name );
  mapped_drug = map.( drug_fields{correct_drug_index} );

  date_str = [ 'day_' date ];
  ind = obj.where( date_str );
  if ( ~any(ind) ), fprintf( '\n Could not find ''%s''', date_str ); end;
  
  obj( 'drugs', ind ) = { mapped_drug };
end

end