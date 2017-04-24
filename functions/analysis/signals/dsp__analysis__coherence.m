function outs = dsp__analysis__coherence(signals, varargin)

params = struct(...
    'within',{{'administration','trialtypes','outcomes','drugs','epochs','monkeys','days'}}, ...
    'takeMean', false, ...
    'subtractReference', false, ...
    'method', 'multitaper', ...
    'ids', [] ...
);

params = paraminclude('Params__signal_processing', params);
params = parsestruct(params,varargin);
within = params.within;
combs = getcombs( signals, within );
store_coh = DataObject();
trial_ns = cell( 1, size(combs,1) );
stp = 1;
for i = 1:size( combs, 1 )
  fprintf( '\nProcessing %d of %d', i, size(combs, 1) );
  
  ind = signals.where( combs(i, :) );
  if ( ~any(ind) ), continue; end;

  bla = signals.only( [combs(i, :) {'bla'}] );
  acc = signals.only( [combs(i, :) {'acc'}] );

  acc_channels = unique( acc('channels') );
  bla_channels = unique( bla('channels') );

  product = allcomb( {acc_channels(:), bla_channels(:)} );

  for k = 1:size(product, 1)
    one_acc = acc.only( product{k, 1} );
    one_bla = bla.only( product{k, 2} );
    [coh, freqs] = coherence( one_bla, one_acc ...
      , 'method', params.method ...
      , 'takeMean', params.takeMean ...
    );
    current_trial_index = signals.where( [combs(i, :) {'acc'} product(k, 1)] );
    labels = acc.labelbuilder( combs(i, :) );
    labels.sites = { ['site__' num2str(stp)] };
    store_coh = store_coh.append( DataObject({coh}, labels) );
    if ( ~isempty(params.ids) )
      trial_ns{stp} = params.ids( current_trial_index );
    end
    stp = stp + 1;
  end
end

store_coh = SignalObject( store_coh, signals.fs, signals.time );
freqs = freqs(:, 1);
empties = cellfun( @isempty, trial_ns );
trial_ns(empties) = [];

outs.coherence = store_coh;
outs.freqs = freqs;
outs.ids = trial_ns;

end