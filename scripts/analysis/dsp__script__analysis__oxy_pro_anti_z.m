%%  GET zscores
zscores = stats.cellfun( @(x) x.zscores, 'UniformOutput', false );
zscores = zscores.cellfun( @(x) x.meanacross('days'), 'UniformOutput', false );

%%  SEPARATE current -- zscored -- alternative method
current = getdata( unpack(  zscores.only( {'normalizedPower', 'proVAnti'} ) ) );
current = current.subtract_across( 'post', 'pre', 'postMinusPre' );
% current = current.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );

%%  SEPARATE current -- zscored
current = getdata( unpack( zscores.only( {'coherence', 'postMinusPre'} ) ) );
current = current.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );

%%  PLOT

[~, combs] = getindices( current, { 'outcomes', 'drugs', 'regions' } );
clims.otherMinusNone = [-1 1];
clims.selfMinusBoth = [-5 1];

for i = 1:size(combs,1)
separators = combs(i,:);
% separators = { 'otherMinusNone', '  oxytocin', 'bla' };
% separators = { 'selfMinusBoth' };
plt = current.only( separators );

lims = clims.( separators{1} );

plot__spectrogram( plt, 'fromTo', [-500 500], 'freqLimits', [0 100], 'clims', lims );

%  SAVE
saveas(gcf, [separators{:}], 'epsc');
saveas(gcf, [separators{:}], 'png'); close gcf;

end

%%  GET real 
real = stats.cellfun( @(x) x.real, 'UniformOutput', false );
real = real.cellfun( @(x) x.meanacross('days'), 'UniformOutput', false );
%%  SEPARATE current -- real -- across drugs
current = getdata( unpack( real.only( {'coherence', 'postMinusPre'} ) ) );
current = current.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
%%  SEPARATE current -- real -- within drug
current = getdata( unpack( real.only( {'normalizedPower', 'proVAnti'} ) ) );
current = current.subtract_across( 'post', 'pre', 'postMinusPre' );
%%
close all;