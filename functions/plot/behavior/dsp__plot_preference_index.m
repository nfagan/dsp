function dsp__plot_preference_index( pref, varargin )

params = struct( ...
  'yLim', [] ...
);
params = parsestruct( params, varargin );

outs = unique( pref('outcomes') );
means = zeros( 1, numel(outs) );
errs = zeros( 1, numel(outs) );
for i = 1:numel(outs)
  extr = pref.only( outs{i} );
  means(i) = mean( extr.data );
  errs(i) = SEM( extr.data );
end

barwitherr( errs, means );
set( gca, 'xticklabel', outs );

if ( ~isempty(params.yLim) )
  ylim( params.yLim );
end

end