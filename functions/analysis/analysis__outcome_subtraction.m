function out = analysis__outcome_subtraction(obj)

sb = subtract_within(obj.only('self'), obj.only('both'), 'outcomes', 'selfMinusBoth');
on = subtract_within(obj.only('other'), obj.only('none'), 'outcomes', 'otherMinusNone');

out = [sb;on];

end