function store = SignalObject__mean_across_pairs(obj, label1, label2, replacewith)

first = obj.only( label1 );
second = obj.only( label2 );

assert( count(first,1) == count(second,1), ...
    'Unequal number of items in first and second objects' );
assert( all( [~isempty(first), ~isempty(second)] ), 'At least one object is empty' );
assert( strcmp(obj.dtype, 'cell'), 'This function only works on objects of dtype cell' );

[~, field] = obj == label1; field = field{1};
[~, field2] = obj == label2; field2 = field2{1};

assert( strcmp(field,field2), 'Cannot take a mean across pairs of different fields' );

within = obj.fieldnames( '-except', field );

indices = obj.getindices( within );

store = DataObject();

for i = 1:numel(indices)
    extr = obj( indices{i} );
    
    first_extr = extr.only( label1 );
    second_extr = extr.only( label2 );
    
    for k = 1:count(first_extr, 1)
        store = store.append( each_cell( first_extr(k), second_extr(k) ) );
    end
    
end

store = store.collapse( field );

if ( nargin < 4 ); return; end;

store = store.setfield( field, replacewith );

end

function first_extr = each_cell( first_extr, second_extr )

assert( all([ numel(first_extr.data) == 1, numel(second_extr.data) == 1 ]), ...
    'More than one cell of data in the object' );

first_extr_data = first_extr.data{1};
second_extr_data = second_extr.data{1};

save_size = size( first_extr_data );

first_extr_data = first_extr_data(:); second_extr_data = second_extr_data(:);

assert( length(first_extr_data) == length(second_extr_data), 'Unequal number of elements' );

meaned = mean([first_extr_data second_extr_data], 2);

meaned = reshape( meaned, save_size );

first_extr.data = {meaned};

end