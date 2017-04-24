function [coherence,freq] = SignalObject__coherence(a_signals,b_signals,varargin)

params = struct(...
    'takeMean', true ...
);

params = paraminclude('Params__signal_processing',params);
params = parsestruct(params,varargin);

chronux_params = struct( ...
    'tapers', [1.5 2], ...
    'Fs', 1e3 ...
);

if ~isa(b_signals,'SignalObject')
    error('The second input must be a signal object');
end

fs = a_signals.fs;

if fs ~= b_signals.fs;
    error('Sampling rates must match between objects');
end


if ( isa(a_signals.data, 'double') )
  a_signals = windowed_data( a_signals, params.stepSize, params.windowSize );
  b_signals = windowed_data( b_signals, params.stepSize, params.windowSize );
else
  a_signals = windowconcat(a_signals);
  b_signals = windowconcat(b_signals);
end

take_mean = params.takeMean;
freqs = params.freqs;

if ~strcmp( params.method, 'multitaper' )
    freq = zeros( numel(freqs), numel(a_signals) );
end

if take_mean && ~strcmp(params.method, 'multitaper')
    coherence = zeros( size(freq) );
else coherence = cell( 1, numel(a_signals) );
end

for i = 1:length(a_signals);
    one_window_a = a_signals{i};
    one_window_b = b_signals{i};
    
    one_window_a = one_window_a';
    one_window_b = one_window_b';
    
    if ( ~strcmp( params.method, 'multitaper' ) )
        [C,f] = mscohere(one_window_a,one_window_b,[],[],freqs,fs);
    else
        [C,~,~,~,~,f] = coherencyc(one_window_a, one_window_b, chronux_params );
        
        if ( take_mean && i == 1 )
            coherence = zeros( numel(f), numel(a_signals) );
            freq = zeros( size( coherence ) );
        end
    end
    
    if ( size(C,1) == 1 ); C = C'; end;
    if ( size(f,1) < size(f,2) ); f = f'; end;    %   store column-wise
    
    if take_mean
        C = mean(C,2); 
        coherence(:, i) = C;
        freq(:, i) = f;
    else
        coherence{i} = C;
        freq(:,i) = f;
    end
end

end

% params.tapers = [11 5];
% params.pad = -1;
% params.Fs = fs;
% params.fpass = [0 max_freq];
    
    

