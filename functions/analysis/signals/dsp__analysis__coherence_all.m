function store = dsp__analysis__coherence_all(signals, varargin)

days = unique( signals('days') );
store = Container();
for i = 1:numel(days)
  fprintf( '\n - Processing day %d of %d', i, numel(days) );
  bla = signals.only( {'bla', days{i}} );
  acc = signals.only( {'acc', days{i}} );  
  bla_channels = unique( bla('channels') );
  acc_channels = unique( acc('channels') );  
  product = allcomb( {bla_channels, acc_channels} );
  for k = 1:size( product, 1 )
    fprintf( '\n\t - Processing channel combination %d of %d', k, size(product, 1) );
    one_bla = bla.only( product{k, 1} );
    one_acc = acc.only( product{k, 2} );
    assert( shape(one_bla, 1) == shape(one_acc, 1), 'Sizes do not match' );
    [coh, freqs] = coherence( one_bla, one_acc, varargin{:} );
    arr = SignalContainer.get_trial_by_time_double( coh );
    one_bla.data = arr;
    one_bla = one_bla.add_field( 'sites', ['site__' num2str(k)] );
    bla_range = one_bla.trial_stats.range;
    acc_range = one_acc.trial_stats.range;
    one_bla.trial_stats.range = max( [bla_range, acc_range], [], 2 );
    store = append( store, one_bla );
  end
end

store = update_frequencies( store, freqs(:, 1) );

end

% params = struct(...
%     'within',{{'administration','trialtypes','outcomes','drugs','epochs','monkeys','days'}}, ...
%     'takeMean', false, ...
%     'subtractReference', false, ...
%     'method', 'multitaper', ...
%     'ids', [] ...
% );
% 
% params = paraminclude('Params__signal_processing', params);
% params = parsestruct(params,varargin);

% [coh, freqs] = coherence( one_bla, one_acc ...
%       , 'method',   params.method ...
%       , 'takeMean', params.takeMean ...
%     );

%     coh = cellfun( @(x) x', coh, 'un', false );
%     arr = cell( size(coh{1}, 1), size(coh, 2) );
%     for j = 1:size(coh{1}, 1)
%       for l = 1:size(coh, 2)
%         arr{j,l} = coh{l}(j, :);
%       end
%     end


% outs.coherence = store;
% outs.freqs = freqs(:, 1);
% outs.ids = ids;


% if ( use_cont )
% else
%       store = store.append( DataObject(arr, one_bla.labels) );
%       if ( ~isempty(params.ids) )
%         full_ind = signals.where( {'bla', days{i}, product{k, 1}} );
%         ids = [ids; params.ids(full_ind)];
%       end
%     end    

% 
% if ( ~use_cont )
%   store = SignalObject( store, signals.fs, signals.time );
% else store = update_frequencies( store, freqs(:, 1) );
% end