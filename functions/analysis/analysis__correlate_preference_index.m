function store = analysis__correlate_preference_index(obj, signals)

within = obj.fieldnames('-except', {'days', 'outcomes'});
[indices, combs] = getindices(obj, within);

for i = 1:numel(indices)
    
    selfboth = only( obj(indices{i}), 'selfMinusBoth' );
    othernone = only( obj(indices{i}), 'otherMinusNone' );
    
    extr = signals.only( combs(i,:) );
    
    selfboth_correlation = do_correlation( selfboth, extr, {'self','both'} );
    othernone_correlation = do_correlation( othernone, extr, {'other','none'} );
    
    recombined = selfboth_correlation.append(othernone_correlation);
    
    if ( i == 1 ); store = recombined; continue; end;
    
    store = store.append( recombined );
    
end


end

function output = do_correlation(data, signals, outcomes)

days = unique( data('days') );

prefindex = zeros( 1, numel(days) );
extr_data = zeros( size(prefindex) );

for i = 1:numel(days)
    
    oneday_data = data.only(days{i});
    
    oneday_out1 = signals.only({days{i}, outcomes{1}});
    oneday_out2 = signals.only({days{i}, outcomes{2}});
    
    ntrials_out1 = count( oneday_out1, 1 );
    ntrials_out2 = count( oneday_out2, 1 );
    
    prefindex(i) = (ntrials_out1 - ntrials_out2) / (ntrials_out1 + ntrials_out2);
    extr_data(i) = oneday_data.data;
    
end

[r,p] = corr( prefindex', extr_data' );

output = data(1); output = output.collapse('days');
output.data = { struct('r', r, 'p', p) };

end
