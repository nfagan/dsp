io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'measures', 'coherence', 'meaned', 'targacq' );
measure = io.read( p, 'frequencies', [0, 100] );

%%

measure = dsp2.process.format.fix_administration( measure );
measure = dsp__remove_bad_days_and_blocks( measure );

%%

new_days = { '05232017', '05252017', '05262017', '05272017', '05292017', '05302017', '06012017' };
new_days = dsp2.util.general.prepend( new_days, 'day__' );

extr = measure;
extr( 'epochs' ) = 'targacq';
extr = extr.add_field( 'age' );
extr = extr.rm( {'errors', 'cued'} );

ind = extr.where( new_days );
extr( 'age', ind ) = 'new';
extr( 'age', ~ind ) = 'old';

non_injection_days = extr.only( 'unspecified' );
non_injection_days = non_injection_days.only( 'pre' );
% non_injection_days( 'administration' ) = 'pre';
non_injection_days( 'drugs' ) = 'saline';

others = extr.rm( 'unspecified' );

extr = non_injection_days.append( others );

extr = extr.only( {'pre'} );

labs = extr.labels.add_category( 'site__' );
inds = labs.get_indices({'days', 'sites'});
daysite = cell( shape(labs, 1), 1 );
for i = 1:numel(inds)
  daysite( inds{i} ) = { sprintf( 'dayxsite%d', i) };
end
%%
selected = unique( daysite );
selected = datasample( selected, 16 );

inds = cellfun( @(x) strcmp(daysite, x), selected, 'un', false );
inds = inds';
inds = [ inds{:} ];
inds = any( inds, 2 );

old_ind = extr.where( 'old' );
extr2 = extr.keep( old_ind | inds );

% rands = 1:256;
% rands = datasample( rands, 16 );
% rands = arrayfun( @(x) [ 'site__', num2str(x) ], rands, 'un', false );

% ind = extr.where( [{'new'}, rands] );
% other_days = extr.where( 'new' ) & ~ind;
% extr = extr.keep( ~other_days );

extr2 = extr2.do( {'monkeys', 'regions', 'outcomes', 'drugs', 'administration', 'days', 'age'}, @mean );

%%

F = gcf;
clf( F );

out = extr2.only( {'self'} );

out = out.do( {'monkeys', 'age', 'regions'}, @mean );

out.spectrogram( {'monkeys', 'age', 'regions', 'outcomes'}, 'shape', [1 3], 'clims', [.66 .86], 'colorMap', 'jet');

%%

figure;

pl = ContainerPlotter();
pl.error_function = @ContainerPlotter.std_1d;

out = extr.only( {'self'} );
out = out.time_freq_mean( [0 100], [50 97] );
out = out.do( {'days', 'outcomes', 'sites'}, @mean );

h = pl.plot_by( out, 'days', 'outcomes', 'monkeys' );
set( h, 'ylim', [.55, 1] );

