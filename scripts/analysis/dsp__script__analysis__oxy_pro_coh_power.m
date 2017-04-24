cd( fullfile( pathfor( 'secondGrantData' ), '121516', 'signals' ) );
load( 'kuro_oxy.mat' );
cd( fullfile( pathfor( 'secondGrantData' ), '102116', 'signals' ) );
load( 'kuro_saline_all.mat' ); kuro_sal = kuro_mag;
%%

epoch = 'reward';

analysis_type = 'coherence';

options = { ...
    'manipulations', 'none', ...
    'collapseAdministration', false, ...
    'setDrugsToSaline', false ...
};

sal = dsp__get_preprocessed_signals( kuro_sal, epoch, analysis_type, options{:} );
oxy = dsp__get_preprocessed_signals( kuro_oxy, epoch, analysis_type, options{:} );
combined = sal.perfield( oxy, @append );

%%

ztransforms = DataObject();

labels.type = { analysis_type };
labels.epoch = { epoch };

ztransform_pre = analysis__zTransform( combined.only('pre'), 'normalizedPower' );
ztransform_post = analysis__zTransform( combined.only('post'), 'normalizedPower' );

ztransform_pre = DataObjectStruct( ztransform_pre ); ztransform_post = DataObjectStruct( ztransform_post );
ztransform = ztransform_pre.perfield( ztransform_post, @append );
ztransforms = ztransforms.append( DataObject( {ztransform}, labels ) );

%%

labels.type = { analysis_type };
labels.epoch = { epoch };

ztransform_pre = analysis__zTransform( combined.only('pre'), 'coherence' );
ztransform_post = analysis__zTransform( combined.only('post'), 'coherence' );

ztransform_pre = DataObjectStruct( ztransform_pre ); ztransform_post = DataObjectStruct( ztransform_post );
ztransform = ztransform_pre.perfield( ztransform_post, @append );
ztransforms = ztransforms.append( DataObject( {ztransform}, labels ) );

%%

% stats = DataObject();

types = { 'normalizedPower', 'coherence' };

for i = 1:numel( types )
    one_type = ztransforms.only( types{i} );
    labels = one_type.labels;
    extr = one_type.data{1};
    extr = extr.foreach( @dsp__match_outcomes );
    extr = analysis__helper__transform( extr, 'proVAnti' );
        
    extr = extr.foreach( @dsp__match_outcomes_across_administration );
    extr = extr.subtract_across( 'post', 'pre', 'postMinusPre' );
    
    extr_stats = analysis__permuted_stats( extr, 'computeZ', true );
    
    labels.manipulations = { 'postMinusPre' };
    
    stats = stats.append( DataObject( {extr_stats}, labels ) );
    
end


