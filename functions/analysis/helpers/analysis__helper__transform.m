function out = analysis__helper__transform(obj, type)

obj = validate_obj( obj );

switch type
    case { 'receivedVForgone', 'receivedMinusForgone', 'forgoneMinusReceived' }
        
        %   take a mean across outcomes, and replace labels with
        %   'selfAndBoth', etc.
        
        sb = obj.meanacrosspairs( 'self', 'both', 'selfAndBoth' );
        on = obj.meanacrosspairs( 'other', 'none', 'otherAndNone' );
        
        %   recombine perfield
        
        out = perfield( on, sb, @vertcat );
    case 'proAntiRedefined'
        
        ob = obj.meanacrosspairs( 'other', 'both', 'otherAndBoth' );
        sn = obj.meanacrosspairs( 'self', 'none', 'selfAndNone' );
        
        out = perfield( ob, sn, @vertcat );        
    
    case 'proVAnti2'
        
        pro = obj.subtract_across( 'both', 'self', 'bothMinusSelf' );
        anti = obj.subtract_across( 'other', 'none', 'otherMinusNone' );
        
        out = perfield( pro, anti, @vertcat );
        
    case { 'proVAnti', 'proMinusAnti' }
        pro = obj.subtract_across( 'self', 'both', 'selfMinusBoth' );
        anti = obj.subtract_across( 'other', 'none', 'otherMinusNone' );
        
        out = perfield( pro, anti, @vertcat );
    case 'proAndAnti'
        anti = obj.meanacrosspairs( 'self', 'none', 'selfAndNone' );
        pro = obj.meanacrosspairs( 'both', 'other', 'otherAndBoth' );
        
        out = perfield( pro, anti, @vertcat );
    otherwise
        error( 'Unrecognized transformation type ''%s''', type );
end

switch type
    case 'forgoneMinusReceived'
        out = out.subtract_across( 'otherAndNone', 'selfAndBoth', 'forgoneMinusReceived' );
    case 'receivedMinusForgone'
        out = out.subtract_across( 'selfAndBoth', 'otherAndNone', 'receivedMinusForgone' );
    case 'proMinusAnti'
        out = out.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    otherwise
        return;
end

end

function obj = validate_obj(obj)

if ( isstruct(obj) )
    obj = DataObjectStruct(obj);
end

assert( isa(obj, 'DataObjectStruct'), 'Input <obj> must be a DataObjectStruct' );

end