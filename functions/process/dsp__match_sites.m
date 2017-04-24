function out = dsp__match_sites(obj)

repeated_region = 'acc';

assert( isa(obj, 'SignalObject'), ...
  'Input must be a SignalObject; was a ''%s''', class(obj) );

fields = obj.fieldnames();

assert( any(strcmp(fields, 'channels')), ...
  'Run this function after adding the field ''channels'' to the object' );

fs = obj.fs; time = obj.time;
obj = Container.create_from( obj );
indices = obj.get_indices( {'days'} );
out = Container();
% out = out.preallocate( zeros(obj.shape(1)*2, obj.shape(2)), obj.nfields()+1 );
site_n = 0;
for i = 1:numel(indices)
  tic;
  fprintf( '\n %d of %d', i, numel(indices) );
  extr = obj( indices{i} );
  repeated = extr.only( repeated_region );
  repeated_channels = unique( repeated('channels') );
  others = extr.remove( repeated_region );
  other_regions = unique( others('regions') );
  for j = 1:numel(repeated_channels)
    site_n = site_n + 1;
    new_site_name = ['site__' num2str(site_n)];
    new_repeated = repeated.only( repeated_channels{j} );
    new_repeated = new_repeated.add_field( 'sites', new_site_name );
    out = out.append( new_repeated );
%     out = out.populate( new_repeated );
    for k = 1:numel(other_regions)
      one_other = others.only( other_regions{k} );
      one_other = one_other.add_field( 'sites', new_site_name );
      out = out.append( one_other );
%       out = out.populate( one_other );
    end
  end
end
% toc;
out = SignalObject( DataObject(out.data, out.label_struct()), fs, time );

end