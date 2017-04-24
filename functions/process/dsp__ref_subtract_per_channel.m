function reconverted = dsp__ref_subtract_per_channel(obj)

assert( isa(obj, 'SignalObject'), 'Initial input must be a SignalObject' );
converted = Container.create_from( obj );
ref = converted.only('ref');
assert( ~ref.isempty(), 'Reference signals are not in the object' );
others = converted.remove( 'ref' );
other_regions = unique( others('regions') );
for i = 1:numel( other_regions )
  other_ind = others.where( other_regions{i} );
  reg = others.keep( other_ind );
  channels = unique( reg('channels') );
  for k = 1:numel(channels)
    ind = reg.where( channels{k} );
    extr_reg = reg.keep( ind );
    %   collapse the regions and channels fields of the current region and
    %   reference electrode, then subtract target region - reference
    %   opc means "perform operation after collapsing"
    subtracted = opc( extr_reg, ref, {'regions', 'channels'}, @minus );
    subtracted.labels = extr_reg.labels;
    reg(ind) = subtracted;
  end
  others(other_ind) = reg;
end

reconverted = SignalObject( DataObject(others.data, others.label_struct()), ...
  obj.fs, obj.time );

end