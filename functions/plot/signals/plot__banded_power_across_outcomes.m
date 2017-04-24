function plot__banded_power_across_outcomes(power_struct)

means = power_struct.means;
errors = power_struct.errors;
bands = power_struct.bands;

if ( ~any(strcmp( fieldnames(power_struct), 'subfolder' )) )
    subfolder = 'test';
else subfolder = power_struct.subfolder;
end

epoch = char( unique( means('epochs') ) );

within = means.fieldnames( '-except', 'outcomes' );
indices = means.getindices(within);

% limits = get_per_band_limits(means, errors, numel(bands));
limits = get_limits(means, errors);

for i = 1:numel(indices)
    
    extr_means = means(indices{i});
    extr_errors = errors(indices{i});
    
    outcomes = unique( extr_means('outcomes') );
    
    figure('units','normalized','outerposition',[0 0 2 2], 'visible', 'off'); hold on;
    
%     limits = get_limits( extr_means, extr_errors );
    
    for j = 1:numel(outcomes)
        
        one_outcome_means = extr_means.only(outcomes{j});
        one_outcome_errors = extr_errors.only(outcomes{j});
        
        for b = 1:numel(bands)
            
            subplot(numel(bands), 1, b);
            
            one_band_means = one_outcome_means.cellfun( @(x) x(b,:), 'UniformOutput', false);
            one_band_errors = one_outcome_errors.cellfun( @(x) x(b,:), 'UniformOutput', false);
            
            mean_data = one_band_means.data{1};
            error_data = one_band_errors.data{1};

            plus_error = mean_data + error_data;
            minus_error = mean_data - error_data;
            
            h(j) = plot(mean_data', 'linewidth', 2); hold on;
            
%             if j == 1
            
            plot(plus_error', 'color', [0.5, 0.5, 0.5]);
            plot(minus_error', 'color', [0.5, 0.5, 0.5]);
            
%             else
%                 plot(plus_error', 'k');
%                 plot(minus_error', 'k');
                
%             end
            
            prettify();
        end
        
        
    end
    
    save_plot(gcf, extr_means(1), epoch, subfolder);
   
end

%{
    clean up the plot
%}

function prettify()

timelabels = dsp__Plotter.timelabels(means.time);
set(gca, 'xtick', 1:numel(timelabels));
set(gca, 'xticklabels', timelabels);

ylim(limits);
% ylim(limits{b});

if j == numel(outcomes)
    legend(h, outcomes);
end

title( [num2str( bands{b}(1) ) ' - ' num2str( bands{b}(2) ) ' hz'] );

if b == numel(bands)
    xlabel( sprintf('Time (ms) from %s', char(unique(one_band_means('epochs')))) );
end

end


end

function save_plot(fig, obj, epoch, subfolder)

plotdirectory = fullfile( pathfor('secondGrantPlots'), '102116' );
subfolder = fullfile(plotdirectory, epoch, 'banded_power', subfolder);

if ( exist(subfolder, 'dir') ~= 7 ); mkdir(subfolder); end;

identifier = dsp__Plotter.create_identifier(obj);

saveas( fig, fullfile( subfolder, identifier ) , 'png' );
saveas( fig, fullfile( subfolder, identifier ) , 'epsc' );

end


%{
    auto scale axes
%}

function limits = get_limits(means, errors)
    
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

function limits = get_per_band_limits(means, errors, nbands)

limits = cell( 1, nbands );

for i = 1:nbands
    
    band_means = means.cellfun( @(x) x(i,:), 'UniformOutput', false );
    band_errors = errors.cellfun( @(x) x(i,:), 'UniformOutput', false );
    
    limits{i} = get_limits(band_means, band_errors);
    
end

end
