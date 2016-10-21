function collapsed = plot__power_vs_magnitude(obj)

within = obj.label_fields;
within = within( ~strcmp(within, 'magnitudes') );

regions = unique( obj('regions') );
outcomes = unique( obj('outcomes') );
magnitudes = {'low', 'medium', 'high'};

% indices = obj.getindices(within);

for i = 1:numel(regions)
    collapsed.(regions{i}) = collapse_within_region(obj.only(regions{i}), outcomes);
    figure; 
    plot( collapsed.(regions{i})' ); title(regions{i});
    legend(outcomes);
    set(gca,'xtick', 1:numel(magnitudes));
    set(gca,'xticklabel',magnitudes);
    ylim([.8 1.8]);
end

% collapsed = layeredstruct({outcomes, magnitudes});

end

function collapsed = collapse_within_region(obj, outcomes)

% outcomes = unique( obj('outcomes') );
magnitudes = {'low', 'medium', 'high'};

collapsed = zeros( numel(outcomes), numel(magnitudes) );

for i = 1:numel(outcomes)
    
    for k = 1:numel(magnitudes)
        
        extr = obj.only({outcomes{i}, magnitudes{k}});
        
        collapsed(i,k) = mean( extr.data );
        
    end
    
end

% plot(collapsed);

end