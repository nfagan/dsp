function obj = SignalObject__time_freq_mean(obj, time_bounds, freq_bounds, varargin)

params = paraminclude('Params__signal_processing');
params = parsestruct(params, varargin);

%{
    make sure we can do the test
%}

validate_obj(obj);
validate_bounds(time_bounds);
validate_bounds(freq_bounds);

%{
    get an index of the desired freq / time bounds
%}

freqs = params.freqs;
time = obj.time;

freq_index = freqs >= freq_bounds(1) & freqs <= freq_bounds(2);
time_index = time >= time_bounds(1) & time <= time_bounds(2);

assert( all( [any(freq_index), any(time_index)] ), ...
    'Could not find the desired frequencies or times' );

%{
    for each cell in <obj.data>, take a mean across the desired times and
    frequencies
%}

obj = obj.cellfun( @(x) mean(mean(x(freq_index, time_index))) );

end

function validate_bounds(bounds)

assert( numel(bounds) == 2, 'Bounds must be a two-element vector' );
assert( bounds(1) < bounds(2), 'The first element of <bounds> must be less than the second' );

end

function validate_obj(obj)

assert( strcmp(obj.dtype, 'cell'), 'Run this after running an analysis function' );
assert( isa(obj.data{1}, 'double'), 'Run this after running an analysis function' );

end