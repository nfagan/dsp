function obj1 = dsp__get_matrix(obj1, obj2)

assert( all([isa(obj1, 'Container'), isa(obj2, 'Container')]) ...
  , ' All objects must be Containers' );
size_msg = 'Each object''s data must be a column vector.';
assert( shape(obj1, 2) == 1 && shape(obj2, 2) == 1, size_msg );
assert( ndims(obj1.data) == 2 && ndims(obj2.data) == 2, size_msg );
assert( shape(obj1, 1) == shape(obj2, 1), ['Dimension mismatch between' ...
  , ' behavioral measure and signal measure'] );

obj2 = obj1.match( obj2 );
obj1.data(:, 2) = obj2.data(:, 1);

end