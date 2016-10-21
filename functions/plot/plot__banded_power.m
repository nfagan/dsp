function plot__banded_power(power_struct)

means = power_struct.means;
errors = power_struct.errors;
bands = power_struct.bands;

limits = get_limits();

for i = 1:count(means,1)
    extr_means = means(i);
    mean_data = extr_means.data{1};
    
    extr_errors = errors(i);
    error_data = extr_errors.data{1};
    
    plus_error = mean_data + error_data;
    minus_error = mean_data - error_data;
    
    figure('visible', 'off');
    plot(mean_data'); hold on;
    plot(plus_error', 'color', [0.5, 0.5, 0.5]);
    plot(minus_error', 'color', [0.5, 0.5, 0.5]); hold off;
    
    prettify();
    save_plot();
    
end

close all;

%{
    set axes labels, limits, etc.
%}

function prettify()
    time = means.time;
    timelabels = repmat( {''}, 1, numel(time) );
    
    for k = 1:5:numel(timelabels)
        timelabels{k} = num2str( time(k) );
    end
    
    timelabels{end} = num2str( time(end) );
    
    set( gca, 'xtick', 1:numel(timelabels) );
    set( gca, 'xticklabel', timelabels );
    
    xlabel( sprintf( 'Time (ms) from %s', char(extr_means('epochs')) ) );
    
    ylim(limits);
    
    band_labels = cell( size(bands) );
    for k = 1:numel(band_labels)
        band_labels{k} = [num2str(bands{k}(1)) ' to ' num2str(bands{k}(2))];
    end
    
    legend(band_labels);
    
end

%{
    auto scale axes
%}

function limits = get_limits()
    
    for k = 1:numel(means.data)
        
        current_max = max( max(means.data{k} + errors.data{k}) );
        current_min = min( min(means.data{k} - errors.data{k}) );
        
        if ( k == 1 );
            global_max = current_max; global_min = current_min;
            continue;
        end
        
        if ( global_max < current_max ); global_max = current_max; end;
        if ( global_min > current_min ); global_min = current_min; end;
        
    end
    
    limits = [ global_min, global_max ];
    
end

function save_plot()
    id = create_identifiers( extr_means );
    
    plot_directory = fullfile( pathfor('secondGrantPlots'), '101816' );
    subfolder = 'targetacquire_fixed/banded_power';
    
    saveas(gcf, fullfile(plot_directory, subfolder, id), 'png');
end


end


function id = create_identifiers(obj)

fields = obj.label_fields;

for i = 1:numel(fields)
    labels = char( unique(obj(fields{i})) );
    
    if ( i == 1 ); id = labels; continue; end;
    
    id = sprintf('%s_%s', id, labels);
end

end