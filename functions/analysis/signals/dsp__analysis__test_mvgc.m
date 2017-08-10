function dsp__analysis__test_mvgc(signals, var_specifiers)

%% Parameters

DO_SHUFFLE = false;

regmode   = 'OLS';  % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
icregmode = 'LWR';  % information criteria regression mode ('OLS', 'LWR' or empty for default)

morder    = 'AIC';  % model order to use ('actual', 'AIC', 'BIC' or supplied numerical value)
momax     = 32;     % maximum model order for model order estimation

acmaxlags = [];     % maximum autocovariance lags (empty for automatic calculation)

tstat     = '';     % statistical test for MVGC:  'F' for Granger's F-test (default) or 'chi2' for Geweke's chi2 test
alpha     = 0.05;   % significance level for significance test
mhtc      = 'FDR';  % multiple hypothesis test correction (see routine 'significance')

fs        = signals.fs;    % sample rate (Hz)
fres      = [];     % frequency resolution (empty for automatic calculation)

if ( DO_SHUFFLE )
  bla = signals.only( 'bla' );
  bla_channels = bla( 'channels' );
  bla_channel = bla_channels{1};
  bla = bla.only( bla_channel );
  bla_data = bla.data;
%   perm_ind = randperm( size(bla_data, 1) );
  perm_ind = randperm( size(bla_data, 2) );
%   bla_data = bla_data( perm_ind, : );
  bla_data = bla_data( :, perm_ind );
  bla.data = bla_data;
  acc = signals.only( 'acc' );
  acc_channels = acc( 'channels' );
  acc_channel = acc_channels{1};
  acc = acc.only( acc_channel );
  signals = acc.append( bla );
%   signals = signals.rm( 'bla' );
%   signals = signals.append( bla );
end

[X, ids] = dsp2.process.format.get_mvgc_data( signals, var_specifiers );

nvars =     size( X, 1 );
nobs =      size( X, 2 );
ntrials =   size( X, 3 );

%%

[AIC, BIC, moAIC, moBIC] = tsdata_to_infocrit( X, momax, icregmode );

% Plot information criteria.

figure(1); clf;
plot_tsdata( [AIC BIC]', {'AIC','BIC'}, 1/fs );
title( 'Model order estimation' );

if ( isequal(morder, 'AIC') )
  morder = moAIC;
else
  disp( morder );
  error( 'The above model order was not recognized.' );
end

[A, SIG] = tsdata_to_var( X, morder, regmode );

[G, info] = var_to_autocov( A, SIG, acmaxlags );

var_info( info, true ); % report results (and bail out on error)

%%  time domain

F = autocov_to_pwcgc( G );

assert( ~isbad(F, false), 'GC calculation failed' );

% Significance test using theoretical null distribution, adjusting for multiple
% hypotheses.

pval = mvgc_pval( F, morder, nobs, ntrials, 1, 1, [], tstat );
sig  = significance( pval, alpha, mhtc );

figure(2); clf;
subplot(1,3,1);
plot_pw(F);
title('Pairwise-conditional GC');
subplot(1,3,2);
plot_pw(pval);
title('p-values');
subplot(1,3,3);
plot_pw(sig);
title(['Significant at p = ' num2str(alpha)])

%%  freq domain

f = autocov_to_spwcgc( G, fres );

% Plot spectral causal graph.

figure(3); clf;
h = plot_spw( f, fs, [0, 500] );
set( h, 'ylim', [0, .1] );

%%  

% Check that spectral causalities average (integrate) to time-domain
% causalities, as they should according to theory.

fprintf('\nchecking that frequency-domain GC integrates to time-domain GC... \n');
Fint = smvgc_to_mvgc(f); % integrate spectral MVGCs
mad = maxabs(F-Fint);
madthreshold = 1e-5;
if mad < madthreshold
    fprintf('maximum absolute difference OK: = %.2e (< %.2e)\n',mad,madthreshold);
else
    fprintf(2,'WARNING: high maximum absolute difference = %e.2 (> %.2e)\n',mad,madthreshold);
end

d = 10;
