function subtracted = subtract_within_outcome(obj1, obj2, field, id)

type_msg = 'Both inputs must be SignalObjects';
field_msg = 'Both objects must have a field named ''outcomes''';

assert( isa(obj1, 'SignalObject'), type_msg );
assert( isa(obj2, 'SignalObject'), type_msg );

assert( obj1.islabelfield('outcomes'), field_msg );
assert( obj2.islabelfield('outcomes'), field_msg );
assert( ischar(id), 'The identifier <id> must be a string' );

obj1('outcomes') = id;
obj2('outcomes') = id;

subtracted = obj1 - obj2;

end