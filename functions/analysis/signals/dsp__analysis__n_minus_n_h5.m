function mdls = dsp__analysis__n_minus_n_h5()

io = dsp_h5( fullfile(pathfor('DATABASE'), 'dsp.h5') );
base_group = '/Measures/Signals';

combs = allcomb( { ...
    {'non_common_averaged'} ...
  , {'coherence'} ...
  , {'per_trial'} ...
  , {'reward', 'targacq'} ...
} );

time_freq = { [0 300], [45 65] };

mdls = Container();

predict_type = 'coherence_predicts_choice';

for i = 1:size( combs, 1 )
  ref_type = combs{i, 1};
  measure_type = combs{i, 2};
  resolution = combs{i, 3};
  epoch = combs{i, 4};
  
  group_path = strjoin( {base_group, ref_type, measure_type, resolution, epoch}, '/' );
  meaned_path = strjoin( {base_group, ref_type, measure_type, 'meaned', epoch}, '/' );
  
  measure = io.read( group_path );
  meaned_measure = io.read( meaned_path );
  meaned_measure = meaned_measure.rm( {'errors', 'cued'} );
  
  measure.trial_ids = dsp__get_trial_ids( measure );
  measure = measure.keep_within_range( .3 );
  measure = measure.time_freq_mean( time_freq{:} );
  measure = dsp__remove_bad_days_and_blocks( measure );
  measure = measure.rm( {'errors', 'cued'} );
  %   for non-injection days, set blocks 1 and 2 -> pre
  ind = measure.where( {'block__1', 'block__2', 'unspecified'} );
  measure( 'administration', ind ) = 'pre';
  
  bad_sites = dsp__identify_bad_sites( meaned_measure, {'outcomes', 'administration', 'trialtypes'} );
  
  for k = 1:size( bad_sites, 1 )
    ind = measure.where( bad_sites(k, :) );
    measure = measure.keep( ~ind );
  end
  
  switch ( predict_type )
    case 'coherence_predicts_choice'
      pro = measure.replace( {'self', 'none'}, 'antisocial' );
      pro = pro.replace( {'both', 'other'}, 'prosocial' );
      
      measure_combs = allcomb( { ...
        { 'saline', 'oxytocin' } ...
        { 'pre', 'post' }
      });

      labels.methods = { ref_type };
      labels.measures = { measure_type };
      labels.epochs = { epoch };
      labels.preceding = { 'was_any' };
      labels.current = { 'is_any' };
      labels.outcomes = { strjoin( pro('outcomes'), '_' ) };
      
      str_freqs = strjoin( arrayfun(@num2str, time_freq{2}, 'un', false), '_' );
      str_freqs = [ str_freqs, 'hz' ];
      str_time = strjoin( arrayfun(@num2str, time_freq{1}, 'un', false), '_' ); 
      str_time = [ str_time, 'ms' ];
      
      labels.times = { str_time };
      labels.frequencies = { str_freqs };
      
      ned = dsp__n_minus_n( pro, 1, [] );
      mdl = dsp__analysis__n_minus_n_predicts( ned, 'outcomes' );
      mdls = mdls.append( Container({mdl}, labels) );
      %   non-drug condition; don't restrict by oxy v. sal
      measure_combs(end+1, :) = { 'pre', 'pre' };
      
      for k = 1:size( measure_combs, 1 )
        curr = ned.only( 'current' );
        prev = ned.only( 'previous' );
        ind = prev.where( measure_combs(k, :) );
        prev = prev.keep( ind );
        curr = curr.keep( ind );
        combined = prev.append( curr );
        mdl = dsp__analysis__n_minus_n_predicts( combined, 'outcomes' );
        
        labels.preceding = { ['was_' strjoin(measure_combs(k, :), '_')] };
        labels.current = { 'is_any' };
        mdls = mdls.append( Container({mdl}, labels) );
      end
    case 'coherence_predicts_coherence'  
      pro = measure.replace( {'self', 'none'}, 'antisocial' );
      pro = pro.replace( {'both', 'other'}, 'prosocial' );

      measure_combs = allcomb( { ...
          {'prosocial', 'antisocial'} ...
        , {'antisocial', 'prosocial'} ...
      });
    
      pro = pro.rm( 'errors' );

      labels.methods = { ref_type };
      labels.measures = { measure_type };
      labels.epochs = { epoch };

      for k = 1:size( measure_combs, 1 )
        preceding_is = measure_combs(k, 1);
        current_is = measure_combs(k, 2);
        ned = dsp__n_minus_n( pro, 1, {preceding_is, current_is} );
        mdl = dsp__analysis__n_minus_n( ned );

        labels.preceding = { ['was_' preceding_is{1}] };
        labels.current = { ['is_' current_is{1}] };

        mdls = mdls.append( Container({mdl}, labels) );
      end 
    otherwise
      error( 'Unrecognized `predict_type` ''%s''', predict_type );
  end
  
end