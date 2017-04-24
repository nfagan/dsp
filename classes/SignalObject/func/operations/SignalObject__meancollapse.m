function collapsed = SignalObject__meancollapse( obj, field )

assert( islabelfield(obj, field), ...
    sprintf('The field ''%s'' does not exist in the object', field) );

uniques = obj.uniques(field);

assert( numel(uniques) > 1, sprintf( 'The field %s is already collapsed', field ) );

current = uniques{1}; uniques = uniques(2:end);

collapsed = obj;

i = 1;

while i < numel(uniques)
    collapsed = collapsed.meanacrosspairs( current, uniques{i}, uniques{i} );
    current = uniques{i};
    next = obj.only( uniques{i+1} );
    collapsed = collapsed.append( next );
    i = i + 1;
end

end
