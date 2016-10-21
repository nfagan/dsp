function means_and_errors = analysis__banded_power(obj, varargin)

params = struct(...
    'bands', {{ [0 4], [5 8], [9 13], [14 30], [31 70] }}, ...
    'meanWithinDay', true ...
);
params = paraminclude( 'Params__signal_processing', params );
params = parsestruct(params, varargin);

bands = params.bands;

%{
    input validation
%}

validate_input(obj, bands);

%{
    collapse days
%}

if ( isa( obj.data{1}, 'double' ) )
    obj = transform_to_cell(obj);
end

%   collapse trials

if params.meanWithinDay
    obj = mean_within_day(obj); 
end
    
if ( length(unique(obj('days'))) > 1 )
    obj = combine_trials_across_days(obj);
end

%{
    find where freqs == bands{i}
%}

band_indices = get_band_indices(params.freqs, bands);

%{
    get a mean across trials, within each bands{k}
%}

for i = 1:count(obj,1)
    
    extr = obj(i); data = extr.data{1};
    
    means = zeros( numel(band_indices), size(data,2) );
    errors = zeros( numel(band_indices), size(data,2) );
    
    for k = 1:numel(band_indices)
        current_index = band_indices{k};
        
        band_mean = cellfun( @(x) mean(x(current_index,:)), data, ...
            'UniformOutput', false );
        
        means(k,:) = cellfun( @mean, band_mean );
        errors(k,:) = cellfun( @SEM, band_mean );
    end
    
    means_obj = extr; means_obj.data = {means};
    error_obj = extr; error_obj.data = {errors};    
    
    if ( i == 1 )
        store_means = means_obj; store_errors = error_obj; 
        continue;
    end
    
    store_means = store_means.append( means_obj );
    store_errors = store_errors.append( error_obj );
    
end

means_and_errors.means = store_means;
means_and_errors.errors = store_errors;
means_and_errors.bands = bands;


end

function indices = get_band_indices(freqs, bands)

indices = cell( size(bands) );

for i = 1:numel(bands)
    indices{i} = freqs >= bands{i}(1) & freqs <= bands{i}(2);
end

end

function validate_input(obj, bands)

assert( iscell(bands), 'bands must be a cell array of matrices' );
assert( all(cellfun(@(x) numel(x) == 2, bands)), 'each band must have two elements' );
% assert( iscell(obj.data), ...
%     'run this after running an analysis function with preserveTrials = true' );
% assert( iscell(obj.data{1}), ...
%     'run this after running an analysis function with preserveTrials = true' );

end

function store_collapsed = combine_trials_across_days(obj)

within = obj.fieldnames('-except', 'days');

indices = obj.getindices(within);

for i = 1:numel(indices)
    
    extr = obj(indices{i});
    days = unique( extr('days') );
    
    for k = 1:numel(days)        
        one_day = extr.only(days{k});
        
        %   make sure trials are stored column-wise
        
        if ( size(one_day.data{1}{1},1) == 1 )
            data = one_day.data{1};
            one_day.data = { cellfun( @(x) x', data, 'UniformOutput', false ) };
        end
        
        if ( k == 1 )
            combined_data = one_day.data{1}; continue;
        end

        for j = 1:numel(one_day.data{1});
            combined_data{j} = [combined_data{j} one_day.data{1}{j}];
        end        
    end
    
    collapsed = extr(1); collapsed.data = {combined_data}; collapsed = collapsed.collapse('days');
    
    if ( i == 1 )
        store_collapsed = collapsed; continue;
    end
    
    store_collapsed = store_collapsed.append(collapsed);    
end

end

function obj = mean_within_day(obj)

all_data = obj.data;

for i = 1:numel(all_data);
    all_data{i} = cellfun( @(x) mean(x,2), all_data{i}, 'UniformOutput', false );
end

obj.data = all_data;

end

function obj = transform_to_cell(obj)

all_data = obj.data;
data = cell( size(all_data) );

assert( isa(data{1}, 'double'), 'The data are already stored in a cell array' );

for i = 1:numel(data)
    for k = 1:size(all_data{i}, 2)
        data{i} = [data{i} {all_data{i}(:,k)}]; 
    end
end

obj.data = data;

end