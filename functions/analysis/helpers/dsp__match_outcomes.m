function matched = dsp__match_outcomes( obj, outcome_pairs )

if ( nargin < 2 ), outcome_pairs = { {'self', 'both'}, {'other', 'none'} }; end;

within = obj.fieldnames( '-except', {'outcomes','days'} );

indices = obj.getindices( within );

matched = DataObject();

for i = 1:numel( indices )
    extr = obj( indices{i} );
    
    for k = 1:numel( outcome_pairs )
        out1 = extr.only( outcome_pairs{k}{1} );
        out2 = extr.only( outcome_pairs{k}{2} );
        
        assert( ~isempty(out1) & ~isempty(out2), 'Could not find the desired pair' );
        
        alldays = intersect( out1.uniques('days'), out2.uniques('days') );
        
        matched = matched.append( out1.only(alldays) );
        matched = matched.append( out2.only(alldays) );
        
        
    end
    
end

end
