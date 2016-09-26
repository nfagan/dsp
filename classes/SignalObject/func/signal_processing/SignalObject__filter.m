function obj = SignalObject__filter(obj,varargin)

params = struct(...
    'filterType', 'zeroPhase', ...
    'cutoffs', [2.5 250], ...
    'order', 2 ...
);

params = parsestruct(params,varargin);

signals = obj.data;
fs = obj.fs;

%{
    validation
%}

assert(numel(params.cutoffs) == 2,'''cutoffs'' must be a two-element vector');
assert(params.cutoffs(1) < params.cutoffs(2),['The first element of ''cutoffs''' ... 
    , ' must be smaller than the second']);

%   convert freq cutoffs -> normalized frequency

f1 = params.cutoffs(1) / (fs/2);
f2 = params.cutoffs(2) / (fs/2);

switch params.filterType
    case 'zeroPhase'
        filt_fnc = @filtfilt;
    case 'filter'
        filt_fnc = @filter;
    otherwise
        Error('Unrecognized filterType ''%s''',params.filterType);
end

switch obj.dtype
    case 'double'
        obj.data = apply_filter(signals,filt_fnc,f1,f2,params.order);
    case 'cell'
        obj.data = cellfun(@(x) apply_filter(x,filt_fnc,f1,f2,params.order), ...
            signals,'UniformOutput',false);
    otherwise
        Error('Cannot filter a SignalObject with dtype ''%s''',obj.dtype);
end

end

function filtered = apply_filter(signals,filt_fnc,f1,f2,n)

[b,a] = butter(n,[f1 f2]);

%   - note messy transpositions, because our signals are stored row-wise,
%   whereas the filter function operates column-wise

filtered = filt_fnc(b,a,signals')';

end