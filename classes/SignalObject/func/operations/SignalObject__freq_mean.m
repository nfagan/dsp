function obj = SignalObject__freq_mean( obj, bands, varargin )

assert( strcmp(obj.dtype, 'cell'), 'Cannot take a mean of raw signals' );
assert( iscell(bands), '<bands> must be a cell array of two element vectors' );
assert( all( cellfun(@(x) isa(x, 'double'), bands ) ), ...
    '<bands> must be a cell array of two element vector' );
assert( all( cellfun(@(x) numel(x) == 2, bands ) ), ...
    '<bands> must be a cell array of two element vectors' );

params = paraminclude( 'Params__signal_processing.mat' );

params = parsestruct( params, varargin );

freqs = params.freqs;

assert( numel(freqs) == size(obj.data{1}, 1), '<freqs> do not match the object''s dimensions' );

data = obj.data;

for i = 1:numel(data)
    matrix = zeros( numel(bands), size(data{i},2) );
    for k = 1:numel(bands)
        ind = freqs >= bands{k}(1) & freqs <= bands{k}(2);
        matrix(k,:) = mean( data{i}(ind,:) );
    end
    data{i} = matrix;
end

obj.data = data;

end