function dsp__container_z_trans()

io = DSP_IO();

combs = allcomb( { ...
    { 'coherence_non_multitapered' } ...
  , { 'common_averaged' } ...
  , { 'reward', 'targacq' } ...
} );

base_load_path = fullfile( pathfor('ANALYSES'), '020317' );
base_label_path = fullfile( pathfor('ANALYSES'), '020317', 'shuffled', 'labels_no_errors' );
base_save_path = fullfile( pathfor('ANALYSES'), '020317', 'ztrans/without_errors_pre_and_post' );

set_post_z = { 'days', 'monkeys', 'drugs' };

for i = 1:size( combs, 1 )
  fprintf( '\n\n\n\nIter %d of %d\n\n\n\n', i, size(combs, 1) );
  
  measure_type = combs{i, 1};
  method = combs{i, 2};
  epoch = combs{i, 3};
  
  shared_within = { 'outcomes', 'trialtypes' };
  
  if ( isequal(measure_type, 'coherence') || isequal(measure_type, 'coherence_non_multitapered') )
    within = [ shared_within, {'sites'} ];
  else
    within = [ shared_within, {'channels', 'regions'} ];
  end
  
  full_load_path = fullfile( base_load_path, method, measure_type, epoch );
  full_label_path = fullfile( base_label_path, method, measure_type );
  
  days = io.get_days( full_load_path );
  
  for k = 1:numel(days)
    
    Z = struct();
    
    signal_measure = io.load( full_load_path, 'only', days{k} );
%     if ( ~strcmp(signal_measure('drugs'), 'saline') ), continue; end;
    labels = io.load( full_label_path, 'only', days{k} );
    
    if ( strcmp(signal_measure('drugs'), 'oxytocin') )
      full_within = [ within, {'administration'} ];
      oxy = true;
    else
      full_within = [ within, {'administration'} ];
%       full_within = within; 
      oxy = false;
    end
    
    %   per outcome
    
    signal_measure = signal_measure.rm( {'errors', 'cued'} );
    
    A = dsp__get_distributions( signal_measure, labels, full_within );
    Z.per_outcome = dsp__z_transform( A );
    
    %   per outcome post - pre
%     try
%       post_minus_pre = A.subtract_across( 'post', 'pre', 'postMinusPre' );
%       Z.post_minus_pre = dsp__z_transform( post_minus_pre );
%     catch
%       fprintf( '\n Day %s failed', days{k} );
%     end
    
    %   pro v anti
%     try
%       pro_v_anti = A.subtract_across_mult( ...
%         {'self', 'both', 'selfMinusBoth'}, {'other', 'none', 'otherMinusNone'} );
%       Z.pro_v_anti = dsp__z_transform( pro_v_anti );
%     catch
%       fprintf( '\n Day %s failed', days{k} );
%     end
    
    %   save
    
    z_types = fieldnames( Z );
    for j = 1:numel(z_types)      
      full_save_path = fullfile( base_save_path, method, measure_type, epoch, z_types{j} );
      if ( exist(full_save_path, 'dir') ~= 7 ), mkdir( full_save_path ); end;
%       if ( oxy )
%         Z.(z_types{j}) = Z.(z_types{j}).rm( 'post' );
%         Z.(z_types{j}) = Z.(z_types{j}).collapse( 'administration' );
%       end
      for h = 1:numel(set_post_z)
        Z.(z_types{j})( set_post_z{h} ) = char( signal_measure(set_post_z{h}) );
      end
      io.save( Z.(z_types{j}), full_save_path );      
    end    
  end
  
end

end

function [measure, labels] = rm_from_labels( measure, labels, selectors )

selectors = SparseLabels.ensure_cell( selectors );
for i = 1:numel( selectors )
  ind = labels.where( selectors{i} );
  rm_orders = labels.data( ind );
  rest_orders = labels.data( ~ind );
  while ( ~isempty(rm_orders) )
    current = rm_orders(1);
    current_ind = rm_orders == current;
    greater_than = rest_orders > current;
    rest_orders( greater_than ) = rest_orders( greater_than ) - 1;
    rm_orders( current_ind ) = [];
  end
  labels = labels.keep( ~ind );
  labels.data = rest_orders;
  measure = measure.rm( selectors{i} );
end

end