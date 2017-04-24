function subtracted = SignalObject__subtract_across(obj, selector1, selector2, newname)

obj1 = obj.only(selector1);
obj2 = obj.only(selector2);

assert( all( [~isempty(obj1), ~isempty(obj2)] ), ...
    sprintf('Could not find ''%s'' or ''%s''', selector1, selector2) );

[~, field1] = obj == selector1; field1 = field1{1};
[~, field2] = obj == selector2; field2 = field2{1};

assert( strcmp(field1, field2), 'The selectors must come from the same field' );

obj1 = obj1.collapse(field1);
obj2 = obj2.collapse(field2);

subtracted = obj1 - obj2;

if ( nargin < 4 ); return; end;

subtracted(field1) = newname;

end

