function outstruct = SignalObject__exclude(threshold, instruct)

fields = validate( instruct );

for i = 1:numel(fields)
    instruct.(fields{i}) = ref_subtract( instruct.(fields{i}) );
end

bad_trials = false( count(instruct.(fields{1}), 1), 1 );

for i = 1:numel(fields)
    bad_trials = bad_trials | check_bounds( threshold, instruct.(fields{i}) );
end

outstruct = instruct;

for i = 1:numel(fields)
    outstruct.(fields{i}) = instruct.(fields{i})(~bad_trials);
end

end

function fields = validate(instruct)

fields = fieldnames(instruct);

for i = 1:numel(fields)
    
    onestruct = instruct.(fields{i});
    
    assert( strcmp(onestruct.dtype, 'cell'), 'Call this function after windowing signals' );
    
    if ( i == 1 ); compare = onestruct; continue; end;
    
    assert( count(compare, 1) == count(onestruct, 1), 'Dimensions must be equal between objects' );
end

end

function subtracted = ref_subtract(obj)

regions = unique( obj('regions') );
regions = regions( ~strcmp(regions, 'ref') );

ref = obj.only('ref');

for i = 1:numel(regions)
    reg = obj.only(regions{i});
    
    fixed = reg - ref;
    
    if ( i == 1); subtracted = fixed; continue; end;
    
    subtracted = [subtracted; fixed];
end

end

function complete_index = check_bounds(threshold, obj)

regions = unique( obj('regions') );

% all_out_of_bounds = false( count(obj,1), 1 );

for i = 1:numel(regions)
    
    oneregion = obj.only(regions{i});

    out_of_bounds = cellfun(@(x) ( max(max(x)) - min(min(x)) ) > threshold, oneregion.data);
    out_of_bounds = sum( out_of_bounds,2 ) >= 1;
    
    if ( i == 1 ); all_out_of_bounds = out_of_bounds; continue; end;
    
    all_out_of_bounds = all_out_of_bounds | out_of_bounds;

%     all_out_of_bounds(retain) = out_of_bounds;
end

complete_index = false( count(obj,1), 1 );

for i = 1:numel(regions)
    
    retain = obj.where(regions{i});
    complete_index(retain) = all_out_of_bounds;
    
end

end