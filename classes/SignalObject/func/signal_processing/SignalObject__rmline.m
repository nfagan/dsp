function obj = SignalObject__rmline(obj,varargin)

params = struct(...
    'freqs', 60, ...
    'tapers', [2 3] ...
    );

params = parsestruct(params,varargin);

assert(exist('rmlinesc','file') == 2,['This function requires the chronux toolbox' ...
    , ' to be installed and added to your search path']);

assert(strcmp(obj.dtype,'double'),'Cannot rmline noise from windowed signals');

signals = obj.data';
fs = obj.fs;
f = params.freqs;

chron.tapers = params.tapers;
chron.Fs = fs;

p = .05/(size(signals,1));
plt = 'n';

for i = 1:numel(f)
    signals = rmlinesc(signals,chron,p,plt,f(i));
end

obj.data = signals';

end