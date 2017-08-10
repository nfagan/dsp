%%

conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
meas = 'coherence';
epoch = 'targacq';
p = dsp2.io.get_path( 'measures', meas, 'meaned', epoch );
measure = io.read( p );
measure( 'epochs' ) = epoch;
measure = dsp2.process.format.fix_administration( measure );

%%

meaned = measure;

no_inject = meaned.where( 'unspecified' );
meaned( 'administration', no_inject ) = 'pre';

meaned = meaned.rm( {'errors', 'cued', 'post'} );

days = meaned( 'days' );
datefmt = 'mmddyyyy';
dates = datenum( cellfun(@(x) x(6:end), days, 'un', false), datefmt );
new_date = datenum( '05232017', datefmt );

newdays = days( dates >= new_date );

assert( all(meaned.contains(newdays)) );

meaned = meaned.add_field( 'age', 'old' );

ind = meaned.where( newdays );

meaned( 'age', ind ) = 'new';

meaned = meaned.do( {'outcomes', 'age', 'monkeys', 'regions'}, @mean );

%%

plt = meaned;
plt = plt.only( {'bla', 'hitch', 'old'} );

% plt = plt.do( {'outcomes'}, @mean );

h = plt.spectrogram( {'outcomes', 'monkeys', 'age'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-500, 500] ...
  , 'shape', [2, 2] ...
  , 'clims', [] ...
);

%%

plt = meaned;
regs = plt( 'regions' );
monks = plt( 'monkeys' );

C = dsp2.util.general.allcomb( {regs, monks, {'old'}} );
addtl = dsp2.util.general.allcomb( {regs, {'kuro'}, {'new'}} );
C = [ C; addtl ];
savepath = fullfile( conf.PATHS.plots, '060517', meas, 'fixed_limits' );
dsp2.util.general.require_dir( savepath );

for i = 1:size(C, 1)
  
  plt_ = plt.only( C(i, :) );

  plt_.spectrogram( {'outcomes', 'monkeys', 'age', 'regions'} ...
    , 'frequencies', [0, 100] ...
    , 'time', [-500, 500] ...
    , 'shape', [2, 2] ...
    , 'clims', [.68, .9] ...
  );

  filename = fullfile( savepath, strjoin(C(i, :), '_') );
  saveas( gcf, [filename, '.png'], 'png' );
end
