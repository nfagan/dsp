function obj = dsp__correlate_within(A, B, within)

assert( isa(A, 'Container') && isa(B, 'Container'), ['Expected A and B' ...
  , ' to be Container objects, but they were of class ''%s'' and ''%s'''] ...
  , class(A), class(B) );
assert( A.labels == B.labels, 'The label objects must match between objects' );
assert__shapes_match(A, B);
assert( shape(A, 2) == 1, 'Data in A and B must be column vectors' );

inds = A.get_indices( within );
obj = Container();
for i = 1:numel(inds)
  obj = obj.append( dsp__correlate(A.keep(inds{i}), B.keep(inds{i})) );  
end

end