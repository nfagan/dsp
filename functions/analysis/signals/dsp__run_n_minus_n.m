function mdls = dsp__run_n_minus_n()

io = DSP_IO();

base_load_path = fullfile( pathfor('ANALYSES'), '020317' );

combs = allcomb( { ...
    {'common_averaged'} ...
  , {'coherence'} ...
  , {'reward'} ...
} );

monk_combs = allcomb( { ...
    {'hitch', 'kuro'} ...
  , {'oxytocin', 'saline'} ...
} );

% time_freq = { [0 250], [4 20] };
time_freq = { [0 150], [30 45] };

mdls = Container();

predict_type = 'coherence_predicts_choice';

for i = 1:size( combs, 1 )
  method = combs{i, 1};
  meas = combs{i, 2};
  epoch = combs{i, 3};
  
  measure = Container();
  
  for k = 1:size( monk_combs, 1 )
    full_load_path = fullfile( base_load_path, method, meas, epoch );
    sig_meas = io.load( full_load_path, 'only', monk_combs(k, :) );
    sig_meas = sig_meas.update_label_sparsity();
    sig_meas.trial_ids = dsp__get_trial_ids( sig_meas );
    sig_meas = sig_meas.rm( {'errors', 'cued', 'post'} );
    sig_meas = sig_meas.keep_within_range( .3 );
    sig_meas = sig_meas.time_freq_mean( time_freq{:} );
    sig_meas = sig_meas.do_per( {'monkeys', 'regions', 'drugs', 'outcomes'} ...
      , @dsp__std_threshold, 2 );
    measure = measure.append( sig_meas );
  end  
  
  switch ( predict_type )
    case 'coherence_predicts_coherence'  
      pro = measure.replace( {'self', 'none'}, 'antisocial' );
      pro = pro.replace( {'both', 'other'}, 'prosocial' );

      measure_combs = allcomb( { ...
          {'prosocial', 'antisocial'} ...
        , {'antisocial', 'prosocial'} ...
      });
    
      pro = pro.rm( 'errors' );

      labels.methods = { method };
      labels.measures = { meas };
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
    case 'coherence_predicts_choice'
      pro = measure.replace( {'self', 'none'}, 'antisocial' );
      pro = pro.replace( {'both', 'other'}, 'prosocial' );
      
%       measure_combs = { 'prosocial'; 'antisocial' };
      measure_combs = allcomb( { ...
        { 'saline', 'oxytocin' } ...
        { 'pre', 'post' }
      });

      labels.methods = { method };
      labels.measures = { meas };
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
      
      for k = 1:size( measure_combs, 1 )
        curr = ned.only( 'current' );
        prev = ned.only( 'previous' );
        ind = prev.where( measure_combs(k, :) );
        prev = prev.keep( ind );
        curr = curr.keep( ind );
        combined = prev.append( curr );
        mdl = dsp__analysis__n_minus_n_predicts( combined, 'outcomes' );
        
        labels.preceding = { ['was_' measure_combs{k, 1}] };
        labels.current = { 'is_any' };
        mdls = mdls.append( Container({mdl}, labels) );
      end

%       for k = 1:size( measure_combs, 1 )
%         preceding_is = measure_combs(k, 1);
%         ned = dsp__n_minus_n( pro, 1, {preceding_is, []} );
%         mdl = dsp__analysis__n_minus_n_predicts( ned, 'outcomes' );
% 
%         labels.preceding = { ['was_' preceding_is{1}] };
%         labels.current = { 'is_any' };
% 
%         mdls = mdls.append( Container({mdl}, labels) );
%       end
%       
%       ned = dsp__n_minus_n( pro, 1, [] );
%       mdl = dsp__analysis__n_minus_n_predicts( ned, 'outcomes' );
%       
%       labels.preceding = { 'was_any' };
%       labels.current = { 'is_any' };
%       
%       mdls = mdls.append( Container({mdl}, labels) );
    otherwise
      error( 'Unrecognized `predict_type` ''%s''', predict_type );
  end
  
end