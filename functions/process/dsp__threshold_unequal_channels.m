function recombined = dsp__threshold_unequal_channels( combined )

if ( ~isa(combined, 'Structure') )
  assert( isa(combined, 'DataObjectStruct'), ...
    'Input must be a Structure or DataObjectStruct; was a ''%s''', class(combined) );
  combined = Structure( combined.objects );
  convert_to_struct = true;
end
recombined = Structure.create( combined.fields(), DataObject() );
regs = combined.reward.uniques( 'regions' );
assert( ~any(strcmp(regs, 'ref')), ...
  'Call this function after reference subtracting per channel' );
for reg = regs(:)'
  sep = combined.only( reg );
  sep = SignalObject__exclude( .3, sep.objects, 'subtractReference', false );
  recombined = recombined.swise( sep, @append );
end

if ( convert_to_struct ), recombined = DataObjectStruct( recombined.objects ); end;
end
