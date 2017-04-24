function plot__z_line_plots(obj, type, varargin)

params = struct(...
    'timeBounds', [-150 150], ...
    'yLimits', [-3 3], ...
    'subfolder', 'norm_power', ...
    'addErrors', true, ...
    'errors', [], ...
    'toAddStars', [], ...
    'starY', 1.5, ...
    'save', true ...
);
params = parsestruct( params, varargin );

timebounds = params.timeBounds;

try
    regions = obj.uniques('regions');
catch
    regions = {'saline'};
end

storeStars = params.toAddStars;
errors = params.errors;

for i = 1:numel(regions)
    onereg = obj.only(regions{i});
    
    if ( ~isempty( storeStars ) )
        params.toAddStars = storeStars.only( regions{i} );
    end
    
    if ( ~isempty( errors ) )
        params.errors = errors.only( regions{i} );
    end
    
    do_plot(onereg, timebounds, type, params);
end

end

function do_plot(obj, timebounds, type, params)

newstruct.means = obj;

canAddStars = true; outcomes = cell( 1, 2 );

if ~isempty(params.errors)
    newstruct.errors = params.errors; 
end

obj = DataObjectStruct( newstruct );

switch type
    case 'proVAnti'
        first = obj.only({'selfMinusBoth'}); second = obj.only({'otherMinusNone'});
        outcomes{1} = 'selfMinusBoth';
        outcomes{2} = 'otherMinusNone';
    case 'receivedVForgone'
        first = obj.only('selfAndBoth'); second = obj.only('otherAndNone');
        outcomes{1} = 'selfAndBoth';
        outcomes{2} = 'otherAndNone';
    case { 'proMinusAnti', 'receivedMinusForgone' }
        first = obj;
        canAddStars = false;
end

first = first.timemean( timebounds );

first_means = first.means.data{1}(1:73);

h(1) = plot(0:72, first_means, 'b', 'linewidth', 2);

if ~isempty(params.errors)
    hold on;
    errors = repmat( first.errors.data{1}(1:73), 1, 2 );
    errors(:,1) = errors(:,1) + first_means;
    errors(:,2) = first_means - errors(:,2);
    plot([0:72;0:72]', errors, 'b');
end

switch type
    case { 'proMinusAnti', 'receivedMinusForgone' }
    otherwise
        second = second.timemean( timebounds );
        hold on;
        h(2) = plot(0:72, second.means.data{1}(1:73), 'r', 'linewidth', 2);
        
        if ( ~isempty(params.errors) )
            second_means = second.means.data{1}(1:73);
            errors = repmat( second.errors.data{1}(1:73), 1, 2 );
            errors(:,1) = errors(:,1) + second_means;
            errors(:,2) = second_means - errors(:,2);
            plot([0:72;0:72]', errors, 'r');
        end
end

switch type
    case 'proVAnti'
        legend(h,{'Anti', 'Pro'});
    case 'receivedVForgone'
        legend(h,{'Received', 'Forgone'});
    case 'proMinusAnti'
        legend(h,'Pro minus anti');
    case 'receivedMinusForgone'
        legend(h,'Received minus forgone');
end


if ( ~isempty( params.toAddStars ) ) && canAddStars
    
    fprintf('\n adding stars' );
    
    assert( isa( params.toAddStars, 'DataObject' ), 'input must be a DataObject' );
    
    params.toAddStars = params.toAddStars.timemean( timebounds );
    
    distributions = cell( 1, numel(outcomes) );
    
    for i = 1:numel(outcomes)
        oneout = params.toAddStars.only( outcomes{i} );
        assert( ~isempty(oneout), 'Object is empty' );
        
        dat = oneout.data;
        
        for k = 1:numel(dat)
            dat{k} = dat{k}';
        end
        
        distributions{i} = concatenateData( dat );
    end
    
    marksignificant = false( 1, size(distributions,2) );
    
    for i = 1:size( distributions{1},2 )
        [h, p, stats] = ttest2( distributions{1}(:,i), distributions{2}(:,i) );
        marksignificant(i) = p < .05;
    end
    
    sig = find( marksignificant ); sig = sig( sig <= length( first_means ) );
    
    for i = 1:numel(sig)
        plot( sig(i), params.starY, '*', 'color', 'k' );
    end
    
end


if ( ~isempty(params.yLimits) ); ylim( params.yLimits); end;

plotting.filename = dsp__Plotter.create_identifier( obj.means );
plotting.type = params.subfolder;
plotting.epoch = char( obj.means.uniques('epochs') );
plotting.subfolder = sprintf('%s/mean_z_plots/mean_z_trans_%s_%s', ...
    plotting.epoch, plotting.type, type);
plotting.directory = fullfile( pathfor('secondGrantPlots'),'110816', plotting.subfolder );
plotting.fullfile = fullfile( plotting.directory, plotting.filename );

if ( exist(plotting.directory, 'dir') ~= 7 ); mkdir( plotting.directory); end;

if ( params.save )

saveas( gcf, plotting.fullfile, 'png' );
saveas( gcf, plotting.fullfile, 'epsc' );

close gcf;

end

end