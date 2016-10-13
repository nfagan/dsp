function subtracted = subtract_within(obj1, obj2, field, id)

type_msg = 'Both inputs must be SignalObjects';
field_msg = 'Both objects must have a field named ''outcomes''';

assert( isa(obj1, 'SignalObject'), type_msg );
assert( isa(obj2, 'SignalObject'), type_msg );

assert( obj1.islabelfield(field), field_msg );
assert( obj2.islabelfield(field), field_msg );
assert( ischar(id), 'The identifier <id> must be a string' );

obj1(field) = id;
obj2(field) = id;

subtracted = obj1 - obj2;

end