function mdl = dsp__analysis__n_minus_n( obj, category_predictors )

if ( nargin < 2 )
  use_additional_predictors = false;
else
  use_additional_predictors = true;
  category_predictors = Labels.ensure_cell( category_predictors );
end

prev = obj.only( 'previous' );
next = obj.only( 'current' );

assert( all(prev.shape() == next.shape()), ['The shapes of the N-n and N' ...
  , ' trialsets must match exactly.'] );

prev = prev.full();

if ( use_additional_predictors )
  predictor_matrix = get_numeric_predictors( prev, category_predictors );
  predictor_matrix = [prev.data, predictor_matrix];
else
  predictor_matrix = prev.data;
end
responses = next.data;

mdl = fitglm( predictor_matrix, responses );

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




