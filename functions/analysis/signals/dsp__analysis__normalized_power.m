function outs = dsp__analysis__normalized_power( target, baseline, varargin )

params = struct(...
    'within',{{'magnitudes','regions','trialtypes','outcomes','administration','drugs', 'monkeys', 'days'}}, ...
    'normMethod','divide', ...
    'normEpoch', 'magcue', ...
    'trialByTrial', false, ...
    'preserveTrials', true, ...
    'subtractReference', false, ...
    'ids', [] ...
);

exclude = {'within','normEpoch'};

params = paraminclude( 'Params__signal_processing', params );
params = parsestruct( params, varargin );
passed_params = struct2varargin( params, exclude );

within = params.within;

[indices, combs] = getindices( target, within );

store_norm_power = DataObject();
trial_ids = cell( size(indices) );
stp = 1;

for i = 1:length(indices)
    
    fprintf( '\nProcessing %d of %d', i, length(indices) );
    
    to_norm = target( indices{i} );
    norm_by = baseline.only( combs(i, :) );    
    power = norm_power( to_norm, norm_by, passed_params{:} );
    labels = labelbuilder( to_norm,combs(i, :) );
    store_norm_power = store_norm_power.append( DataObject({power}, labels) );
    if ( ~isempty(params.ids) )
      trial_ids{stp} = params.ids( indices{i} );
    end
    stp = stp + 1;
end

store_norm_power = SignalObject( store_norm_power, target.fs, target.time );

outs.power = store_norm_power;

end