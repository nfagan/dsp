function matched = dsp__match_outcomes_across_administration( obj )

within = obj.fieldnames( '-except', {'days', 'outcomes', 'administration'} );

indices = obj.getindices( within );

matched = DataObject();

for i = 1:numel( indices )
    extr = obj( indices{i} );
    
    outs = extr.uniques( 'outcomes' );
    
    for k = 1:numel( outs )
        matched = matched.append( match_within_one_outcome( extr.only( outs{k} ) ) );
    end
end

end

function matched = match_within_one_outcome( obj )

admins = obj.uniques( 'administration' );

all_days = obj.uniques( 'days' );

for i = 1:numel( admins )
    extr = obj.only( admins{i} );
    days = extr.uniques( 'days' );
    all_days = intersect( all_days, days );
end

matched = obj.only( all_days );


end