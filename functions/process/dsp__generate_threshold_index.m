function ind = dsp__generate_threshold_index( obj, threshold, varargin )

params = struct( ...
  'within',{{'administration','trialtypes','outcomes','drugs','epochs','monkeys'}} ...
);
params = parsestruct( params, varargin );

if ( isstruct(obj) ), obj = Structure( obj ); end;
if ( isa(obj, 'DataObjectStruct') ), obj = Structure( obj.objects ); end;
assert( isa(obj, 'Structure'), ['Input must be a struct, DataObjectStruct' ...
  , ' or Structure'] );

fs = obj.fields();
n_fs = numel(fs);
if ( n_fs > 1 )
  current_shape = obj.(fs{1}).count( 1 );
  for i = 2:n_fs
    assert( current_shape == obj.(fs{i}).count( 1 ), ['Each object in the struct' ...
      , 'must have the same number of rows (trials)'] );
  end
end

inds_per_obj = Structure();

for i = 1:n_fs
  inds_per_obj.(fs{i}) = per_object( obj.(fs{i}), threshold, params );
end

current_data = inds_per_obj{1}.data;

for i = 1:n_fs
  new = inds_per_obj.(fs{i});
  new_inds = new.data;
  for k = 1:count( inds_per_obj{1}, 1 )
    new_ind = new_inds{k};
    current_data{k} = current_data{k} & new_ind;
  end
end

ind = inds_per_obj{1};
ind.data = current_data;

end

function labeled_indices = per_object( obj, threshold, params )

within = params.within;
inds = obj.getindices( within );
labeled_indices = DataObject();

for i = 1:numel(inds)
  extr = obj(inds{i});
  channels = unique( extr('channels') );
  for k = 1:numel(channels)
    extr_channel = extr.only( channels{k} );
    data = extr_channel.data;
    mins = min( data, [], 2 );
    maxs = max( data, [], 2 );
    if ( k == 1 )
      in_bounds = ( maxs - mins ) <= threshold;
    else in_bounds = in_bounds & ( maxs - mins ) <= threshold;
    end
    extr_channel = extr_channel(1);
    extr_channel.data = { in_bounds };
    labeled_indices = labeled_indices.append( extr_channel );
  end  
end

end

% function in_bounds = per_object( obj, threshold )
% 
% data = obj.data;
% mins = min( data, [], 2 );
% maxs = max( data, [], 2 );
% 
% in_bounds = ( maxs - mins ) <= threshold;
% 
% end

% if ( isstruct(obj) ), obj = Structure( obj ); end;
% if ( isa(obj, 'DataObjectStruct') ), obj = Structure( obj.objects ); end;
% assert( isa(obj, 'Structure'), ['Input must be a struct, DataObjectStruct' ...
%   , ' or Structure'] );
% 
% fs = obj.fields();
% n_fs = numel(fs);
% if ( n_fs > 1 )
%   current_shape = obj.(fs{1}).count( 1 );
%   for i = 2:n_fs
%     assert( current_shape == obj.(fs{i}).count( 1 ), ['Each object in the struct' ...
%       , 'must have the same number of rows (trials)'] );
%   end
% end
% 
% ind = true( obj{1}.count(1), 1 );
% 
% for i = 1:n_fs
%   ind = ind & per_object( obj.(fs{i}), threshold );
% end