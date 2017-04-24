function [store_coh, freqs, trial_ns] = analysis__coherence(signals,varargin)

params = struct(...
    'within',{{'administration','trialtypes','outcomes','drugs','epochs','monkeys'}}, ...
    'takeMean', true, ...
    'ids', [] ...
);

params = paraminclude('Params__signal_processing', params);
params = parsestruct(params,varargin);

within = params.within;

[indices, combs] = getindices(signals,within);

store_coh = DataObject();

trial_ns = cell( 1, numel(indices) ); stp = 1;

for i = 1:length(indices)
    
    fprintf('\nProcessing %d of %d',i,length(indices));
    
    acc = signals(signals == [combs(i,:) {'acc'}]);
    bla = signals(signals == [combs(i,:) {'bla'}]);
    
    if params.subtractReference
        ref = signals(signals == [combs(i,:) {'ref'}]);
        acc = acc - ref;
        bla = bla - ref;
    end
    
    channels_exist = any( strcmp(signals.fieldnames(), 'channels') );
    if ( channels_exist )
      mult_channels = unique( acc('channels') );
      for k = 1:numel(mult_channels)
        [coh, freqs] = coherence( bla, acc.only(mult_channels{k}), ...
          'method', params.method, 'takeMean', params.takeMean );
        labels = labelbuilder(acc.only(mult_channels{k}), combs(i,:));
        labels.channels = mult_channels(k);
        store_coh = [store_coh; DataObject({coh},labels)];
        if ( isempty(params.ids) )
          trial_ns{stp} = acc( 'trials' ); 
        else trial_ns{stp} = params.ids( signals.where([combs(i,:) mult_channels(k)]) );
        end
        stp = stp + 1;
      end
      continue;
    end
    
    [coh, freqs] = coherence(bla,acc, 'method', params.method, 'takeMean', params.takeMean);
    labels = labelbuilder(acc,combs(i,:));
    store_coh = [store_coh; DataObject({coh},labels)];
    
end

store_coh = SignalObject(store_coh, signals.fs, signals.time);

freqs = freqs(:, 1);

end

