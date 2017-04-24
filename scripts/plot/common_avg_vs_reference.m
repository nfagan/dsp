pl = ContainerPlotter();
n = 1;
%%
subset = S_acc.rwdOn.rm( 'errors' );
enumed = subset.enumerate( 'regions' );

mult_region = cellfun( @(x) numel(x('channels')) > 1, enumed );
chans = enumed{mult_region}('channels');
enumed{mult_region} = enumed{mult_region}.only( chans{1} );
%%
n = n+1;
regs = cellfun( @(x) x(n), enumed, 'un', false );

recomb = regs{1};
for i = 2:numel(regs)
  recomb = recomb.append( regs{i} );
end

pl.default();
pl.x = -1:.001:1.15-.001;
pl.vertical_lines_at = 0;
pl.plot( recomb, 'regions', {'trialtypes', 'trials'} );

%%
n = n+1;
regs = cellfun( @(x) x(n), enumed, 'un', false );
recomb = regs{1};
for i = 2:numel(regs)
  recomb = recomb.append( regs{i} );
end

recomb = recomb.collapse( 'channels' );
recomb = recomb.subtract_across_mult(...
    {'acc', 'ref', 'accMinusRef'} ...
  , {'bla', 'ref', 'blaMinusRef'} ...
  , {'acc', 'cav', 'accMinusCav'} ...
  , {'bla', 'cav', 'blaMinusCav'} ...
);

recomb = recomb.add_field( 'reference_type' );
ind = recomb.where( {'accMinusRef', 'blaMinusRef'} );
recomb( 'reference_type', ind ) = 'referenceSubtracted';
recomb( 'reference_type', ~ind ) = 'commonAveraged';

pl.default();
pl.x = -1:.001:1.15-.001;
pl.y_lim = [];
pl.vertical_lines_at = 0;
h = pl.plot( recomb, 'regions', {'reference_type', 'trialtypes', 'outcomes'} );