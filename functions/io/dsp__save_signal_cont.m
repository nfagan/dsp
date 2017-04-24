function dsp__save_signal_cont( obj, segment_size, folder )

folders = dirstruct( folder, 'folders' );
if ( numel(folders) ~= 0 )
  in = input( sprintf(['\n\nWARNING: Folders already exist in this folder.' ...
    , '\nDo you wish to overwrite them? (y/n)'], folder), 's' );
  if ( isequal(lower(in), 'n') ), return; end;
end

days = unique( obj('days') );
for i = 1:numel(days)  
  full_folder_path = fullfile( folder, days{i} );
  if ( exist(full_folder_path, 'dir') ~= 7 ), mkdir(full_folder_path); end;
  extr = obj.only( days{i} );
  if ( shape(extr, 1) <= segment_size )
    segment_size = shape(extr, 1); 
    break_next = true;
  else break_next = false;
  end
  start = 1;
  stop = start + segment_size - 1;
  id = 1;
  while ( true )
    one = extr( start:stop );
    filename = fullfile( full_folder_path, sprintf('segment__%d.mat', id) );
    save( filename, 'one' );
    if ( break_next ), break; end;
    id = id + 1;
    start = stop + 1;
    stop = start + segment_size - 1;
    if ( stop >= shape(extr, 1) )
      stop = shape(extr,1);
      break_next = true;
    end
  end  
end

end