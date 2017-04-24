function all_stats = analysis__permuted_stats(obj, varargin)

validate_obj( obj );

real = obj.real;
shuffled = obj.shuffled;

%{
    default inputs
%}

%   freq {{[15 30], [35 50]}}
%   time {{[200 350], [0 300]}}

params = struct( ...
    'time', {{[0 300], [0 300], [100 350], [200 350], [200 350]}}, ...
    'freq', {{[30 50], [35 50], [30 50], [15 30], [30 50]}}, ...
    'computeZ', false ...
);

params = parsestruct( params, varargin );

%{
    for every unique combination of unique labels in <real>, get the
    matching shuffled data in <shuffled>; then, for each time-frequency
    cell (i), get the distribution of shuffled.data{:}(i), to compare with
    real.data(i). For statistics, get the mean normalized-power within
    <params.time> and <params.freq> for each shuffled-data point, and test
    against the real mean within the same time-freq limits.

    Store the z-transformed full-data in <zscores>. Store the z-scores and
    p-values for the ROI data in <stats>.

    Output all analyses as struct <all_stats>
%}

within = real.fieldnames();   %   i.e., within every possible combination
[indices, combs] = getindices( real, within );

zscores = DataObject(); %   initialize to store for each loop
stats = DataObject();

for i = 1:numel(indices)
    
    fprintf( '\nProcessing %d of %d', i, numel(indices) );
    
    extr_real = real(indices{i});
    extr_shuffled = shuffled.only( combs(i,:) );    %   combs(i,:) represents
                                                    %   the full set of
                                                    %   labels associated
                                                    %   with indices{i}
    
    if ( params.computeZ )
        extr_z = get_z_score( extr_real, extr_shuffled );
        zscores = zscores.append( extr_z );
    end
    
    extr_stats = get_stats_within_time_and_freq( ...
        extr_real, extr_shuffled, params );
    
    stats = stats.append( extr_stats );
    
end

%   output stats, zscores, the real data, and permuted data

all_stats.stats = stats;
all_stats.zscores = zscores;
all_stats.real = real;
all_stats.shuffled = shuffled;

all_stats = DataObjectStruct( all_stats );

end

%{
    given time limits <params.time> and frequency limits <params.freq>, get
    a mean of the analyses values within those limits, both for the <real>
    data and each data point in <shuffled>. Compute a z-score and p-value
    based on the shuffled distribution.
%}

function stats = get_stats_within_time_and_freq( real, shuffled, params )

if ( isa(params.freq, 'double') ) && ( isa(params.time, 'double') )
    params.time = {params.time}; params.freq = {params.freq};
else
    assert( iscell(params.freq) & iscell(params.time), ...
        ['If specifying multiple frequency bands, put both <time> and <freq>' ...
        , ' in cell arrays'] );
end

assert( numel(params.freq) == numel(params.time), ...
    'Number of time and frequency elements must match' );

store_stats = cell( size(params.freq) );

for i = 1:numel(params.freq)

extr_real = real.timefreqmean( params.time{i}, params.freq{i} );
extr_shuffled = shuffled.timefreqmean( params.time{i}, params.freq{i} );

distribution = fitdist( extr_shuffled.data, 'normal' );
test_val = extr_real.data;

z = (test_val - distribution.mu) / distribution.sigma;
p = 2 * normcdf( -abs(z), 0, 1 );

store_stats{i} = struct( 'z', z, 'p', p, ...
    'freq', params.freq{i}, 'time', params.time{i}  );

end

stats = real;
stats.data = {store_stats};

end

%{
    given an object <shuffled> with N cell-arrays of time-frequency data,
    get a distribution of size [N, 1] of shuffled.data{:}(k)
%}

function distribution = get_distribution( shuffled, k )

data = shuffled.data;

distribution = zeros( numel(data), 1 );

for i = 1:numel(data)
    distribution(i) = data{i}(k);
end

distribution = fitdist( distribution, 'normal' );

end

%{
    given <real> and <shuffled> data, get the z-score of the real data
%}

function zscores = get_z_score( real, shuffled )

real_data = real.data{1};

z_scores = zeros( size(real_data) );

for i = 1:numel(real_data)
    distribution = get_distribution( shuffled, i );
    
    test_val = real_data(i);
    
%     z_scores(i) = abs( (test_val - distribution.mu) / distribution.sigma );
    z_scores(i) = (test_val - distribution.mu) / distribution.sigma;
end

zscores = real;
zscores.data = {z_scores};

end

function validate_obj(obj)

required_fields = {'real', 'shuffled'};

assert( isa(obj, 'DataObjectStruct'), '<obj> must be a DataObjectStruct' );

assert_fields_exist( obj, required_fields );

end

