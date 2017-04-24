function dsp__save_signals( obj, folder )

if ( ~isa(obj, 'Structure') )
  assert( isa(obj, 'DataObjectStruct'), ['Input must be a Structure or' ...
    , ' DataObjectStruct; was a ''%s'''], class(obj) );
  obj = Structure( obj.objects );
end

fs = fields( obj );
for i = 1:numel(fs)
  save_per_field( obj.(fs{i}), fs{i}, folder );
end

end

function save_per_field( obj, name, folder )

data = obj.data;
labels = obj.labels;
fs = obj.fs;
time = obj.time;

save( fullfile(folder, ['data__' name]), 'data', '-v7.3' );
save( fullfile(folder, ['labels__' name]), 'labels', '-v7.3' );
save( fullfile(folder, ['fs__' name]), 'fs', '-v7.3' );
save( fullfile(folder, ['time__' name]), 'time', '-v7.3' );

end