function sig = analysis__permute(type, signals, sample)

%{
    validate inputs
%}

switch type
    case { 'normalizedPower', 'subtractedNormalizedPower' }
        validate__norm(signals, sample);
    otherwise
        validate__common(signals, sample);
end

%{
    perform the desired analysis for <repetitions>, and store each
    repetition in <store>
%}

repititions = 5;

for i = 1:repititions    
    switch type
        case { 'normalizedPower', 'subtractedNormalizedPower' }
            out = permute_norm( signals, sample, type );
        otherwise
            out = permute_nonnorm( signals, sample, type );
    end
    
    if ( i == 1 ); store = out; continue; end;
    
    store = store.append( out );
end

sig = determine_significance( store, sample, .05 );

end

%{
    after getting the permuted values, determine, in each time + freq bin,
    what percent of the sample data is greater than the permuted data
%}

function store_significant = determine_significance(permuted, sample, threshold)

[indices, combs] = getindices( permuted, permuted.fieldnames() );

for i = 1:numel(indices)
    extr_permuted = permuted( indices{i} );
    extr_sample = sample.only( combs(i,:) );
    
    sample_data = abs( extr_sample.data{1} );
    permuted_data = cellfun( @(x) abs(x), extr_permuted.data, 'UniformOutput', false );
    
    n_repetitions = numel(permuted_data);
    
    %{
        non-significant samples are those for which the permuted values are
        greater than or equal to the sample values
    %}
    
    mark_non_significant = zeros( size(sample_data) );
    for k = 1:numel(permuted_data)
        mark_non_significant = mark_non_significant + ( permuted_data{k} >= sample_data );
    end
    
    %{
        significant samples are those for which the frequency of
        non-significant samples is less than <threshold>
    %}
    
    mark_significant = ( mark_non_significant ./ n_repetitions ) < threshold;
    
    %{
        store the significance indicator with the same labels as the
        extracted sample <extr_sample>
    %}
    
    extr_sample.data = {mark_significant};
    
    if ( i == 1 ); store_significant = extr_sample; continue; end;
    
    store_significant = store_significant.append( extr_sample );
end

end

%{
    bulk of analysis
%}

function out = permute_nonnorm(signals, sample, type)

    perm = get_shuffled_index(signals);
    
    signals.data = signals.data(perm);
    
    %{
        process the signals
    %}
    
    signals = window( filter(signals), 50, 150 );
    
    %{
        do the main analysis
    %}
    
    within = sample.fieldnames();
    
    switch type
        case 'coherence'
            out = analysis__coherence(signals, 'within', within);
        case 'oxyMinusSalCoherence'
            out = analysis__coherence(signals, 'within', within);
            out = subtract_within( out.only('post'), out.only('pre'), ...
                'administration', 'postMinusPre' );
            out = subtract_within( out.only('oxytocin'), out.only('saline'), ...
                'drugs', 'OxyMinusSal' );
        case 'valueTuning'
            out = analysis__norm_power(target, base, ...
                'within', within, ...
                'method', 'multitaper', ...
                'subtractReference', false ...
                );
            out = analysis__pev_spect(out);
        otherwise
            error('Unsupported analysis type ''%s''', type);
    end
    
end

%{
    run the analysis for normalized power data
%}

function out = permute_norm(signals, sample, type)

%{
    process the signals -- including reference subtraction, and excluding
    outlier signals
%}

signals = ...
    structfun( @(x) window(filter(x), 50, 150), signals, 'UniformOutput', false );
signals = SignalObject__exclude(.3, signals);

%{
    get the permuted indices
%}

permuted_indices = structfun( @(x) get_shuffled_index(x), signals, ...
    'UniformOutput', false );

fields = fieldnames(signals);

for i = 1:numel(fields)
    current_index = permuted_indices.(fields{i});
    signals.(fields{i}).data = signals.(fields{i}).data(current_index);
end

%{
    do the main analysis
%}

within = sample.fieldnames();

out = analysis__norm_power(signals.toNormalize, signals.baseline, ...
    'within', within, ...
    'method', 'multitaper', ...
    'subtractReference', false ...
);

out = SignalObject__mean_across( out, 'days' );

%{
    do (self - both) and (other - none) subtractions, if applicable
%}

if ( strcmp(type, 'subtractedNormalizedPower') )
    out = analysis__outcome_subtraction(out);
end

end

%{
    perform the permutation
%}

function perm = get_shuffled_index(signals)

perm = randperm( size(signals.data,2) );

perm = repmat( perm, size(signals.data,1), 1 );

end

%{
    make sure we can actually do the test
%}

function validate__common(signals, sample)

assert( all( [isa(signals, 'SignalObject'), isa(sample, 'SignalObject')] ), ...
    'signals and sample must both be SignalObjects' );

assert( strcmp(signals.dtype, 'double'),...
    'raw signals must not be processed / windowed' );
assert( strcmp(sample.dtype, 'cell'), ...
    'sample output must be the result of an analysis__ function');

assert( signals.islabelfield('epochs') && sample.islabelfield('epochs'), ...
    'the signals and/or sample data do not have an ''epochs'' field');

signal_epoch = unique( signals('epochs') );
sample_epoch = unique( sample('epochs') );

assert( length(signal_epoch) == 1 & length(sample_epoch) == 1, ...
    ['The epochs do not match between signals and the sample data, or there' ...
    , ' are multiple epochs in signals'] );

assert( all(signals.time == sample.time), [ 'The time periods for the sample and signals' ...
    , ' do not match' ]);
assert( all(signals.fs == sample.fs), [ 'The sample rates for the sample and signals' ...
    , ' do not match' ]);

end

%{
    if doing a normalized power permutation, do a couple of additional
    checks
%}

function validate__norm(signals, sample)

struct__msg = ['If permuting normalized power, <signals> must be a structure with' ...
    , ' <toNormalize> and <baseline> fields'];

assert( isstruct(signals), struct__msg );
assert( all([isfield(signals, 'toNormalize'), isfield(signals, 'baseline')]) , struct__msg );

validate__common( signals.toNormalize, sample );

end