%{
    analysis__zTransform.m -- peform an analysis of type <type> on a
    SignalObject <obj>, then z-transform by performing the same analysis
    <params.repetitions> times (shuffling <params.shuffleField> on each
    iteration).

    Returns <all_stats>, a structure with fields 'stats' and 'zscores'.
%}

function all_stats = analysis__zTransform(obj, type, varargin)

%{
    establish default parameters
%}

params = struct( ...
    'repetitions', 100, ...
    'shuffleField', 'outcomes', ...
    'subtractAcross', { {{'selfAndBoth', 'otherAndNone', 'receievedMinusForgone'}} }, ...
    'receivedVForgone', false, ...
    'receivedMinusForgone', false, ...
    'forgoneMinusReceived', false, ...
    'proMinusAnti', false, ...
    'proVAnti', false, ...
    'time', [0 200], ...
    'freq', [19 40], ...
    'doStats', false ...
);

params = parsestruct( params, varargin );

%{
    determine which kind of analysis to run, and make sure that the input
    <obj> fits with the <type>
%}

types = determine_types( type );

if ( types.is_normalized )
    validate_norm( obj );
else validate_non_norm( obj );
end

%{
    run the analysis on the real data
%}

actual = do_analysis( obj, types, params );

%{
    for <params.repetitions>, shuffle the outcome labels as appropriate, and
    perform the analysis, storing each iteration in <shuffled>
%}

repetitions = params.repetitions;

shuffled = DataObject();

for i = 1:repetitions
    
    fprintf( '\n\n\nProcessing iteration %d of %d\n', i, repetitions );

    if ( types.is_normalized ) && ( types.is_power )
        permuted = permute_within_region_normalized( obj ); 
    else
        permuted = permute_per_region_per_day( obj );
    end

    permuted = do_analysis( permuted, types, params );

    shuffled = shuffled.append( permuted );

end

all_stats.real = actual;
all_stats.shuffled = shuffled;

if ( ~params.doStats ); return; end;

%{
    for every unique combination of unique labels in <actual>, get the
    matching shuffled data in <shuffled>; then, for each time-frequency
    cell (i), get the distribution of shuffled.data{:}(i), to compare with
    actual.data(i). For statistics, get the mean normalized-power within
    <params.time> and <params.freq> for each shuffled-data point, and test
    against the real mean within the same time-freq limits.

    Store the z-transformed full-data in <zscores>. Store the z-scores and
    p-values for the ROI data in <stats>.

    Output all analyses as struct <all_stats>
%}

within = actual.fieldnames();   %   i.e., within every possible combination
[indices, combs] = getindices( actual, within );

zscores = DataObject(); %   initialize to store for each loop
stats = DataObject();

for i = 1:numel(indices)
    
    extr_actual = actual(indices{i});
    extr_shuffled = shuffled.only( combs(i,:) );    %   combs(i,:) represents
                                                    %   the full set of
                                                    %   labels associated
                                                    %   with indices{i}
    
    extr_z = get_z_score( extr_actual, extr_shuffled );
    
    extr_stats = get_stats_within_time_and_freq( ...
        extr_actual, extr_shuffled, params );
    
    zscores = zscores.append( extr_z );
    stats = stats.append( extr_stats);
end

%   output stats, zscores, the real data, and permuted data

all_stats.stats = stats;
all_stats.zscores = zscores;

end

%{
    run the analysis corresponding to the fields of <types>
%}

function out = do_analysis( obj, types, params )

%   compute normalized power

if ( types.is_power ) && ( types.is_normalized )
    fprintf('\n\nComputing normalized power ... \n');
    
    out = analysis__norm_power( obj.toNormalize, obj.baseline, ...
        'method', 'multitaper', 'subtractReference', false );
    
%   compute raw power

elseif ( types.is_power )
    fprintf('\n\nComputing raw power ... \n');
    
    out = analysis__raw_power( obj, ...
        'method', 'multitaper', 'subtractReference', false );
    
%   compute coherence

elseif ( ~types.is_power ) && ( ~types.is_normalized )
    fprintf('\n\nComputing coherence ... \n');
    
    within = {'administration','trialtypes','outcomes','drugs','epochs','monkeys','days'};
    
    out = analysis__coherence( obj, 'subtractReference', false, 'within', within );
else
    error('Unrecognized analysis type');
end

%   subtract as appropriate

if ( types.is_subtractive )
    fprintf('\n\nSubtracting ... \n');
    
    %   params.subtractAcross contains the inputs to subtract_across()
    %   In the equation: out = object1 - object2, params.subtractAcross{1}{1}
    %   specifies object1, params.subtractAcross{1}{2} specifies object2, and
    %   params.subtractAcross{1}{3} (optionally) sets the name of the new
    %   outcome (e.g., selfMinusBoth). This way, we can specify multiple
    %   subtractions by having multiple cell-arrays of 3 elements each.
    
    subtract_across_inputs = params.subtractAcross;
    
    subtracted = DataObject();
    
    for i = 1:numel(subtract_across_inputs)
        subtracted = subtracted.append( out.subtract_across(subtract_across_inputs{i}{:}) );
    end
    
    out = subtracted;
end

if ( params.receivedVForgone )
    sb = out.only({'self','both'}); on = out.only({'other','none'});
    sb = sb.meanacross( 'outcomes', 'selfAndBoth' );
    on = on.meanacross( 'outcomes', 'otherAndNone' );
    out = sb.append( on );
end

if ( params.proMinusAnti )
    out = out.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
end

if ( params.receivedMinusForgone )
    out = out.subtract_across( 'selfAndBoth', 'otherAndNone', 'receivedMinusForgone' );
elseif ( params.forgoneMinusReceived )
    out = out.subtract_across( 'otherAndNone', 'selfAndBoth', 'forgoneMinusReceived' );
end

%   take a mean across days if computing a form of power (coherence is
%   already specific to each trial, and need not be calculated
%   per-day)

% if ( types.is_power )
%     out = out.meanacross( 'days' );
% end

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
    
    z_scores(i) = abs( (test_val - distribution.mu) / distribution.sigma );
end

zscores = real;
zscores.data = {z_scores};

end

%{
    given time limits <params.time> and frequency limits <params.freq>, get
    a mean of the analyses values within those limits, both for the <real>
    data and each data point in <shuffled>. Compute a z-score and p-value
    based on the shuffled distribution.
%}

function stats = get_stats_within_time_and_freq( real, shuffled, params )

real = real.timefreqmean( params.time, params.freq );
shuffled = shuffled.timefreqmean( params.time, params.freq );

distribution = fitdist( shuffled.data, 'normal' );
test_val = real.data;

z = (test_val - distribution.mu) / distribution.sigma;
p = 2 * normcdf( -abs(z), 0, 1 );

stats = real;
stats.data = { struct('z', z, 'p', p) };

end

%{
    permute the outcome labels separately for each day / site, then
    recombine into one object <obj>
%}

function obj = permute_per_region_per_day(obj)

indices = obj.getindices('days');

for i = 1:numel(indices)
    obj( indices{i} ) = permute_per_region( obj(indices{i}) );
end

end

%{
    permute the outcome labels associated with one region, and then
    apply those labels to each region in <obj>. Thus, labels are shuffled
    compared to the real data, but are (like the real data), consistent
    across regions

    N.B. This only works if we know for sure that all regions have
    identical labels to begin with (in our case, we do).
%}

function permuted = permute_per_region(obj)

regions = unique( obj('regions') );

one_region = obj.only( regions{1} );

%   shuffle the outcome labels, then return them as a cell array

permuted_outcomes = one_region.shufflelabels('outcomes');
permuted_outcomes = permuted_outcomes('outcomes');

permuted = DataObject();

for i = 1:numel(regions)
    one_region = obj.only( regions{i} );
    one_region('outcomes') = permuted_outcomes;
    
    permuted = permuted.append( one_region );
end

end

%{
    we must employ a different procedure for z-transforming
    normalized power, since we must match indices between baseline and
    toNormalize periods. For one region, shuffle the outcome labels for
    that region, within day / site -- then apply those outcome labels to
    each other region.
%}

function store = permute_within_region_normalized(obj)

regions = unique( obj.toNormalize('regions') );

one_region = regions{1}; regions(1) = [];

%   for one region, within day, permute the outcome labels, and return
%   per-day indices of the permuted outcomes

[permuted, shuffled_indices] = permute_normalized( obj.only(one_region) );

store.toNormalize = permuted.toNormalize;
store.baseline = permuted.baseline;

%   if there was only one region in <obj>, we don't need to proceed

if ( isempty(regions) ); store = DataObjectStruct(store); return; end;

%   otherwise, for each additional region, set the outcome labels of both
%   <toNormalize> and <baseline> to those of the first region

for i = 1:numel(regions)
    extr = obj.only(regions{i});
    extr = permute_normalized( extr, shuffled_indices );
    
    store.toNormalize = store.toNormalize.append( extr.toNormalize );
    store.baseline = store.baseline.append( extr.baseline );
end

store = DataObjectStruct(store);

end

%{
    helper function to shuffle labels within a region, within each day.
%}

function [permuted, shuffled_indices] = permute_normalized(obj, shuffled_indices)

days = unique( obj.toNormalize('days') );

if ( nargin < 2 ); shuffled_indices = cell( numel(days), 1 ); end;

%   prepare the storage structure <store> -- create a struct with fields
%   'toNormalize' and 'baseline', and fill each with an empty DataObject

store = layeredstruct( {{'toNormalize', 'baseline'}}, DataObject() );

for i = 1:numel(days)
    
    %   <ind> is an index of the data points in toNormalize that correspond
    %   to days{i}
    
    ind = obj.toNormalize.where( days{i} );
    
    %   <extr> is a new DataObjectStruct; each object in the
    %   structure has been indexed with <ind>, such that each object
    %   contains data corresponding to days{i}
    
    extr = obj.index( ind );
    
    %   shuffled_index is a random permutation of 1 : <number of data
    %   points in extr.toNormalize> OR it is a previously-computed index,
    %   copied from shuffled_indices{i}
    
    if ( nargin < 2 )
        shuffled_index = extr.toNormalize.randperm();
    else shuffled_index = shuffled_indices{i};
    end
    
    %   for each object in extr, rearrange the 'outcomes' according to the
    %   shuffled index. Thus, outcomes are shuffled compared to real data,
    %   but are consistent across baseline and toNormalize epochs
    
    extr = extr.shufflelabels('outcomes', shuffled_index);
    
    %   concatenate each <extr> day back into one object (per epoch)
    
    store.toNormalize = store.toNormalize.append( extr.toNormalize );
    store.baseline = store.baseline.append( extr.baseline );   
    
    shuffled_indices{i} = shuffled_index;
end

%   convert the <store> structure to a DataObjectStruct

permuted = DataObjectStruct(store);

end

%{
    make sure <obj> is of the proper form, if zTransforming non-normalized
    data
%}

function validate_non_norm(obj)

assert( isa(obj, 'SignalObject'), ...
    ['If zTransforming coherence or non-normalized power, <obj> must be a' ...
    , ' SignalObject'] );

end

%{
    make sure <obj> is of the proper form, if zTransforming normalized
    data
%}

function validate_norm(obj)

assert( isa(obj, 'DataObjectStruct'), '<obj> must be a DataObjectStruct' );
assert( all([ any(strcmp(obj.objectfields(), 'toNormalize')), ...
    any(strcmp(obj.objectfields(), 'baseline')) ]), ...
    '<obj> must be a DataObjectStruct with ''baseline'' and ''toNormalize'' fields');

end

%{
    given string <type>, return boolean representations of the type
%}

function types = determine_types( type )

find_func = @(str) ~isempty( strfind(lower(type), str) );

types.is_subtractive = any( find_func('subtracted') );
types.is_power = any( find_func('power') );
types.is_normalized = any( find_func('normalized') );

end