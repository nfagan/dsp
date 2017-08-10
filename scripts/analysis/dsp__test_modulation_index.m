io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'signals', 'complete', 'targacq' );
days = io.get_days( p );
cue = io.read( p, 'only', days{end} );

%%

subbed = dsp2.process.reference.reference_subtract_within_day( cue );

bla = subbed.rm( {'acc', 'ref', 'errors'} );
acc = subbed.rm( {'bla', 'ref', 'errors'} );

% N = 100;
N = acc.shape(1);

for i = 1:N
  
  bla_ = bla(i);
  acc_ = acc(i);

  data = [bla_.data; acc_.data];

  [mod2d, flow, fhigh] = KL_MI2d_TEM( data );
  
  if ( i == 1 )
    mod2d_ = zeros( [N, size(mod2d)] );
  end
  
  mod2d_(i, :, :) = mod2d;
end

mod2d = mod2d_;

%%

bla_ = bla(1:N);

cont = SignalContainer( mod2d, bla_.labels );
cont.frequencies = flow;
cont.start = fhigh(1);
cont.stop = fhigh(end);
cont.step_size = fhigh(2) - fhigh(1);

cont = cont.do( 'regions', @nanmean );

cont.spectrogram( 'regions' );

%%

sj = [ bla_.data(1, :)', acc_.data(1, :)' ];
sj_dft = fft( sj );
% zj = 



%%

[pxy, f] = cpsd( bla_.data(1, :)', acc_.data(1, :)', [], [], 1:200, 1e3 );
blax = pwelch( bla_.data(1, :)', [], [], 1:200, 1e3 );
accx = pwelch( acc_.data(1, :)', [], [], 1:200, 1e3 );

coh2 = abs(pxy.^2) ./ (blax.*accx);

coh = sqrt( coh2 );


