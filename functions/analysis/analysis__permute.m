function analysis__permute(signals, sample, type)

validate(signals, sample);

repititions = 2;

for i = 1:repititions
    out = do_permute(signals, type);
    
    if ( i == 1 ); store = out; continue; end;
    
    store = [store; out];
end

d = 10;

end

%{
    bulk of analysis
%}

function out = do_permute(signals, type)

    %{
        perform the permutation
    %}

    perm = randperm( size(signals.data,2) );
    
    perm = repmat( perm, size(signals.data,1), 1 );
    
    signals.data = signals.data(perm);
    
    %{
        process the signals
    %}
    
    signals = process(signals, 50, 150);
    
    %{
        do the main analysis
    %}
    
    within = {'outcomes', 'administration', 'drugs', 'monkeys', ...
        'trialtypes'};
    
    switch type
        case 'coherence'
            out = analysis__coherence(signals, 'within', within);
        case 'oxyMinusSalCoherence'
            out = analysis__coherence(signals, 'within', within);
            out = subtract_within( out.only('post'), out.only('pre'), ...
                'administration', 'postMinusPre' );
            out = subtract_within( out.only('oxytocin'), out.only('saline'), ...
                'drugs', 'OxyMinusSal' );
        otherwise
            error('Unsupported analysis type ''%s''', type);
    end
    
end

%{
    make sure we can actually do the test
%}

function validate(signals, sample)

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