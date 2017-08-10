io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'signals', 'complete', 'targacq' );
selectors = { 'day__05262017' };
signals = io.read( p, 'only', selectors );

signals = dsp2.process.reference.reference_subtract_within_day( signals );
% signals = signals.filter( 'cutoffs', [10, 250] );
signals = signals.update_range();

%%
signals_ = signals.enumerate( 'regions' );

ind = cellfun( @(x) x.trial_stats.range <= .3, signals_, 'un', false );
ind = [ ind{:} ];
ind = any( ind, 2 );

signals_ = cellfun( @(x) x(ind), signals_, 'un', false );

for i = 1:numel( signals_ )
  channels = signals_{i}('channels');
  channel = channels{1};
  signals_{i} = signals_{i}.only( channel );
end

signals_ = extend( signals_{:} );
signals_ = signals_.rm( {'errors', 'cued'} );

%%
% 
% signals_.data = signals_.data( :, 1000:1500 );
% signals2 = signals_;

% signals2 = signals_.downsample( 250 );
% signals2.data = signals2.data( :, 1:500 );

signals2 = signals_;
% signals2.data = signals2.data( :, 1e3:end );
signals2.data = signals2.data( :, 500:end );

dsp__analysis__test_mvgc( signals2.only('none'), 'regions' );

%%

% trial_n = 1;

[regs, ~, ids] = signals_.enumerate( 'regions' );
hold off;
for i = 1:numel(regs)
  plot( regs{i}.data(trial_n, :) );
  hold on;
end

legend( ids );

trial_n = trial_n + 1;

%%
commandwindow