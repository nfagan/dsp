function [obj, ids] = dsp__prepare_for_coherence( obj )

obj = dsp__ref_subtract_within_day( obj );
ids = dsp__get_trial_ids( obj );

if ( isa(obj, 'Container') )
  obj = obj.to_data_object();
  obj = SignalObject( obj, NaN, NaN );
end

end