function gazes = dsp__get_gaze_frequency( looks, within )

if ( nargin < 2 )
  within = {'days', 'outcomes', 'trialtypes', 'looks_to', 'look_period'};
end

assert( looks.contains('count'), 'The object is missing a ''counts'' label.' );
gazes = looks.only( 'count' );
%   make into frequency
gazes.data = double( gazes.data > 0 );
%   get number of trials within 'days', etc.
Ns = gazes.counts( within );
%   get sum of binary look counts within 'days', etc.
freqs = gazes.do( within, @sum );
%   divide within 'days', etc.
gazes = freqs ./ Ns;
gazes.data = gazes.data * 100;


end