function [status, errs] = dsp__check_one_outer_folder(pathstr, behav)

import dsp2.util.general.dirnames;

status = true;

n_datestr_chars = 8;
date_str_start = 3;
folder_date_str_format = 'mmddyyyy';
picto_folder_date_str_format = 'yyyy-mm-dd HH:MM:SS';

date_fix_func = @(x) ['day__', x(date_str_start:date_str_start+n_datestr_chars-1)];
sesh_fix_func = @(x) ['session__', x(1)];
sesh_num_func = @(x) str2double(x(1));
picto_date_fix_func = @(x) strrep(x(19:end), '__', '_');

subdirs = dirnames( pathstr, 'folders' );
dir_dates = cellfun( date_fix_func, subdirs, 'un', false );
dir_sessions = cellfun( sesh_fix_func, subdirs, 'un', false );
num_sessions = cellfun( sesh_num_func, subdirs );

non_exist = ~behav.contains( dir_dates );

subdirs( non_exist ) = [];
dir_dates( non_exist ) = [];
dir_sessions( non_exist ) = [];

errs = cell( 1, numel(subdirs) );

for i = 1:numel(subdirs)
  subdir = subdirs{i};
  sesh = dir_sessions{i};
  picto_sub_dir = fullfile( pathstr, subdir, 'behavioral data' );
  picto_dirs = dirnames( picto_sub_dir, 'folders' );
  block_ns = arrayfun( @(x) ['block__', num2str(x)], (1:numel(picto_dirs)), 'un', false );
  
  picto_dir_dates = picto_dirs;
  picto_dir_dates = cellfun( @remove_leading_session_id, picto_dir_dates, 'un', false );
  picto_dir_dates = cellfun( picto_date_fix_func, picto_dir_dates, 'un', false );
  picto_dir_dates = cellfun( @match_format, picto_dir_dates, 'un', false );
  picto_date_nums = datenum( datestr(picto_dir_dates, picto_folder_date_str_format) );
  
  [~, ind] = sort( picto_date_nums );
  
  err = {};
  
  if ( ~isequal(ind(:)', 1:numel(picto_dirs)) )
    err{end+1} = sprintf( 'Block subfolders were not in sorted order for %s', subdirs{i} );
    status = false;
  end
      
  for k = 1:numel(picto_dirs)
    picto_dir_folder = fullfile( picto_sub_dir, picto_dirs{k} );
    trial_info_txt = dirnames( picto_dir_folder, '.data.txt' );
    
    assert( numel(trial_info_txt) == 1, 'Too many trial info folders' );
    
    trial_info = dlmread( fullfile(picto_dir_folder, trial_info_txt{1}) );
    
    matching_behav_data = behav.only( [dir_dates(i), {sesh}, block_ns(k)] );
    
    if ( size(trial_info, 1) ~= shape(matching_behav_data, 1) )
      err{end+1} = sprintf( 'Behav data did not correspond to picto block for %s_%s' ...
        , subdirs{i}, picto_dirs{k} );
      status = false;
    end
  end
  
  errs{i} = err;
end

if ( status ), errs = []; end

end

function str = match_format(date_str)

first_component = strrep( date_str(1:10), '_', '-' );
last_component = strrep( date_str(12:19), '_', ':' );

str = [ first_component, ' ', last_component ];

end

function str = remove_leading_session_id(str)

if ( isstrprop(str(1), 'digit') )
  str = str(3:end);
end

end