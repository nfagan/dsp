function mdl = dsp__analysis__n_minus_n_predicts( obj, response )

response = Labels.ensure_cell( response );

prev = obj.only( 'previous' );
next = obj.only( 'current' );

assert( all(prev.shape() == next.shape()), ['The shapes of the N-n and N' ...
  , ' trialsets must match exactly.'] );

next = next.full();
response = get_numeric_predictors( next, response );
predictors = prev.data;
% predictors = [prev.data, get_numeric_predictors( prev, {'outcomes'} )];

mdl = fitglm( predictors, response );

end

function predictor_matrix = get_numeric_predictors( obj, predictors )

predictor_matrix = zeros( shape(obj, 1), numel(predictors) );

for i = 1:numel(predictors)  
  unqs = unique( obj(predictors{i}) );
  for k = 1:numel(unqs)
    ind = obj.where( unqs{k} );
    predictor_matrix(ind, i) = k;
  end  
end

end




