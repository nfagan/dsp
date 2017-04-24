monk_combs = allcomb( { ...
    {'hitch', 'kuro'} ...
  , {'oxytocin', 'saline'} ...
});

full_measure = Container();

for i = 1:size(monk_combs, 1)
  
  measure = io.load( cd, 'only', monk_combs(i, :) );
  measure = measure.update_label_sparsity();
  measure = measure.rm( {'cued', 'errors', 'post'} );
  measure = measure.keep_within_range( .3 );
  meaned = measure.time_freq_mean( [], [0 100] );
  within_std_threshold = dsp__std_threshold_index( meaned ...
    , {'regions', 'drugs', 'outcomes'}, 2 );
  measure = measure.keep( within_std_threshold );
  measure = measure.mean_within( {'monkeys', 'outcomes', 'days', 'regions', 'channels'} );
  
  full_measure = full_measure.append( measure );  
end
%%

full_measure2 = full_measure.subtract_across_mult( {'self','both','selfMinusBoth'}, {'other','none','otherMinusNone'} );

site_type = 'channels';
number_start = 3; % 7

sites = full_measure2.full();
sites = sites.label_struct();
sites = sites.(site_type);
sites = cellfun( @(x) x(number_start:end), sites, 'un', false );
sites = str2double( sites );
sites = Container( sites, full_measure2.labels );
sites = SignalContainer( sites.data, sites.labels );

%%

freqs = { [15, 25], [30, 50], [50, 70] };
outs = { 'selfMinusBoth', 'otherMinusNone' };
freq_outs = allcomb( {freqs, outs} );

for i = 1:size( freq_outs, 1 )
  
freq = freq_outs{i, 1};
out = freq_outs{i, 2};

meaned = full_measure.time_freq_mean( [0 400], freq );

str_freqs = strjoin( arrayfun( @(x) num2str(x), freq, 'un', false ), '_' );
str_freqs = [ str_freqs 'hz' ];
subbed = meaned;
subbed = subbed.only( {'hitch'} );
subbed = subbed.subtract_across_mult( {'other', 'none', 'otherMinusNone'} ...
  , {'self', 'both', 'selfMinusBoth'} );
subbed = subbed.only( out );
% subbed.histogram( 'sites', 'shape', [4 4], 'nBins', 8, 'yLim', [0 15], 'xLim', [-.045 .045] );
subbed.histogram( [], 'yLim', [0 5], 'xLim', [-.045 .045], 'nBins', 3e3 );

saveas( gcf, [out '_' str_freqs], 'epsc' );
saveas( gcf, [out '_' str_freqs], 'png' );

end
%%
pl = ContainerPlotter();
%%

hold on;
reg = 'acc';
site_plt = sites.only( {'hitch', reg} );
meaned_plt = meaned.only( {'hitch', reg} );
days = site_plt( 'days' );
% days = setdiff( days, 'day__02012017' );
pl.marker_size = .2;
pl.y_lim = [];
for i = 1:numel(days)
  pl.scatter( site_plt.only( days{i} ), meaned_plt.only( days{i} ), 'days', 'outcomes' );
end
%%
pl.add_legend = true;
pl.marker_size = 10;
pl.scatter( site_plt, meaned_plt, 'days', 'outcomes' );

%%
pl.default();
% selectors = { 'hitch' };
pl.marker_size = 2;
% pl.scatter( sites.only({'hitch', 'selfMinusBoth'}), meaned.only({'hitch', 'selfMinusBoth'}), [], 'monkeys' );
pl.scatter( sites.only('hitch'), meaned.only('hitch'), [], 'outcomes' );

%%

subbed.histogram( [] );



