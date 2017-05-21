function dsp__plot_spect_across_monks( load_path, base_save_path, epoch, clims, kind, is_z, is_drug )

if ( nargin < 4 ), clims = []; kind = 'oxy_minus_sal'; end;

switch ( epoch )
  case 'targacq'
    time_limits = [ -150 500 ];
  case 'reward'
    time_limits = [ -500 500 ];
  case 'targon'
    time_limits = [ -150 500 ];
  otherwise
    error( 'Unrecognized epoch ''%s''', epoch );
end

pl = ContainerPlotter();
pl.save_outer_folder = base_save_path;

io = DSP_IO();

monk_combs = allcomb( { ...
    {'hitch', 'kuro'} ...
  , {'oxytocin', 'saline'} ...
  } );

if ( ~is_drug )
  monk_combs(end+1, :) = { 'hitch', 'unspecified' };
end

all_monks = Container();

for i = 1:size(monk_combs, 1)
  monk = monk_combs{i, 1};
  drug = monk_combs{i, 2};
  one_monk = io.load( load_path, 'only', {monk, drug} );
  one_monk = one_monk.update_label_sparsity();
  
  if ( isequal(drug, 'unspecified') )
    one_monk = one_monk.only( {'block__1', 'block__2'} );
    one_monk( 'administration' ) = 'pre';
  end
  
  switch ( kind )
    case { 'pro_v_anti', 'pro_minus_anti', 'per_outcome', 'received_v_forgone', 'received_minus_forgone' }
      one_monk = one_monk.rm( {'errors', 'post'} );
    case {'oxy_minus_sal', 'pro_v_anti_drug', 'pro_v_anti_per_drug', 'pro_minus_anti_drug', 'pro_v_anti_oxy_minus_sal', 'pro_minus_anti_oxy_minus_sal' }
      one_monk = one_monk.rm( {'cued', 'errors'} );
    otherwise
      error( 'Unrecognized type ''%s''', kind );
  end
  if ( ~is_z )
    one_monk = one_monk.keep_within_range( .3 );    
  end
%   one_monk = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );

  all_monks = all_monks.append( one_monk );
end

all_monks = dsp__remove_bad_days_and_blocks( all_monks );
%   NEW
bad_sites = dsp__identify_bad_sites( all_monks, {'outcomes', 'administration'} );
for i = 1:size( bad_sites, 1 )
  all_monks = all_monks.only_not( bad_sites(i, :) );
end
%   END NEW

if ( is_z )
  infs = any( any(isinf(all_monks.data), 3), 2 );
  all_monks = all_monks.keep( ~infs );
end

% if ( ~is_z )
%   meaned = all_monks.time_freq_mean( [], [0 100] );
%   within_std_threshold = dsp__std_threshold_index( meaned ...
%     , {'regions', 'monkeys', 'drugs', 'outcomes'}, 2 );
%   all_monks = all_monks.keep( within_std_threshold );
% else
%   infs = any( any(isinf(all_monks.data), 3), 2 );
%   all_monks = all_monks.keep( ~infs );
% end
%% plot per monk

monks = all_monks( 'monkeys' );
for i = 1:numel(monks)
  one_monk = all_monks.only( monks{i} );
  switch ( kind )
    case 'per_outcome'
      meaned = one_monk.mean_within( {'outcomes', 'regions'} );
      shape = [ 2, 2 ];
    case 'oxy_minus_sal'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
      meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
      meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      shape = [ 2, 2 ];
    case 'pro_v_anti_oxy_minus_sal'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
      meaned = manipulation__pro_v_anti( meaned );
      meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
      meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      shape = [1 2];
    case 'pro_minus_anti_oxy_minus_sal'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
      meaned = manipulation__pro_v_anti( meaned );
      meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
      meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      shape = [];
    case 'pro_minus_anti_drug'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
      meaned = manipulation__pro_v_anti( meaned );
      meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
      meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
      meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      shape = [];
    case 'pro_v_anti_per_drug'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
      meaned = manipulation__pro_v_anti( meaned );
      meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
      shape = [1 2];
    case 'pro_v_anti'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'trialtypes'} );
      meaned = meaned.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} );
      shape = [ 1 2 ];
    case 'pro_minus_anti'
      meaned = one_monk.mean_within( {'outcomes', 'regions', 'trialtypes'} );
      meaned = manipulation__pro_v_anti( meaned );
      meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
      shape = [];
    case 'received_v_forgone'
      meaned = one_monk.mean_within( {'outcomes', 'regions'} );
      meaned = manipulation__received_v_forgone( meaned );
      shape = [];
    case 'received_minus_forgone'
      meaned = one_monk.mean_within( {'outcomes', 'regions'} );
      meaned = manipulation__received_v_forgone( meaned );
      meaned = meaned.subtract_across( 'received', 'forgone', 'receivedMinusForgone' );
      shape = [];
    otherwise
      error( 'Unrecognized manipulation ''%s''', kind );
  end
  meaned( 'epochs' ) = epoch;
  if ( ~isempty(strfind(base_save_path, 'coherence')) )
    c = meaned.combs( {'regions', 'trialtypes', 'drugs'} );
  else c = meaned.combs( {'outcomes', 'trialtypes', 'drugs'} );
  end
  for k = 1:size(c, 1)
    one_reg = meaned.only( c(k, :) );
    one_reg.spectrogram( {'outcomes', 'regions', 'monkeys'} ...
      , 'frequencies', [0 100] ...
      , 'clims', clims ...
      , 'shape', shape ...
      , 'fullScreen', true ...
      , 'time', time_limits ...
      , 'rectangle', [] ...
    );
    savestr = strjoin( {monks{i}, strjoin(c(k,:), '_'), epoch}, '_' );
    full_save_path = fullfile( base_save_path, savestr );
    saveas( gcf, [full_save_path '.epsc'], 'epsc' );
    saveas( gcf, [full_save_path, '.svg'], 'svg' );
%     print -painters -depsc test.eps
%     print( gcf, '-painters', '-depsc', [full_save_path '.eps'] );
%     print2eps( full_save_path, gcf );
    saveas( gcf, [full_save_path '.png'], 'png' );
    savefig( gcf, [full_save_path '.fig'] );
  end
%   meaned_lines = meaned.freq_mean( [0 100] );
%   pl.plot_and_save( meaned_lines ...
%     , {'regions', 'trialtypes'} ...
%     , @plot ...
%     , {'outcomes', 'regions', 'monkeys'} ...
%     , [] ...
%   );
  
end
%% plot across monks

switch ( kind )
  case 'per_outcome'
    meaned = all_monks.mean_within( {'outcomes', 'regions'} );
    shape = [ 2, 2 ];
  case 'oxy_minus_sal'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
    meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
    meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
    shape = [ 2, 2 ];
  case 'pro_v_anti'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'trialtypes'} );
    meaned = meaned.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} );
    shape = [ 1 2 ];
  case 'pro_minus_anti_drug'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
    meaned = meaned.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
        , {'other', 'none', 'otherMinusNone'} );
    meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
    meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
    meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    shape = [];
%     shape = [ 2, 1 ];
  case 'pro_v_anti_per_drug'
%     meaned = all_monks.mean_within( {'outcomes', 'regions', 'channels', 'administration', 'drugs'} );
    m_within = { 'days', 'channels', 'outcomes', 'administration' };
    meaned = all_monks.do( m_within, @mean );
    meaned = meaned.collapse_except( {'days', 'channels', 'regions', 'outcomes', 'administration', 'drugs' } );
%     meaned = all_monks.mean_within( {'days', 'regions', 'channels', 'outcomes', 'administration'} );
%     meaned = all_monks.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
    meaned = manipulation__pro_v_anti( meaned );
    meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
    meaned = meaned.do( {'outcomes', 'administration', 'drugs', 'regions'}, @mean );
    shape = [1 2];
  case 'pro_minus_anti'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'trialtypes'} );
    meaned = manipulation__pro_v_anti( meaned );
    meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    shape = [];
  case 'pro_v_anti_oxy_minus_sal'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
    meaned = manipulation__pro_v_anti( meaned );
    meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
    meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
    shape = [1 2];
  case 'pro_minus_anti_oxy_minus_sal'
    meaned = all_monks.mean_within( {'outcomes', 'regions', 'administration', 'drugs'} );
    meaned = manipulation__pro_v_anti( meaned );
    meaned = meaned.subtract_across( 'otherMinusNone', 'selfMinusBoth', 'proMinusAnti' );
    meaned = meaned.subtract_across( 'post', 'pre', 'postMinusPre' );
    meaned = meaned.subtract_across( 'oxytocin', 'saline', 'oxyMinusSal' );
    shape = [];
  case 'received_v_forgone'
    meaned = all_monks.mean_within( {'outcomes', 'regions'} );
    meaned = manipulation__received_v_forgone( meaned );
    shape = [];
  case 'received_minus_forgone'
    meaned = all_monks.mean_within( {'outcomes', 'regions'} );
    meaned = manipulation__received_v_forgone( meaned );
    meaned = meaned.subtract_across( 'received', 'forgone', 'receivedMinusForgone' );
    shape = [];
end
if ( isempty(clims) )
  lims = get_limits( meaned, {'regions', 'trialtypes', 'drugs'} );
  auto_lims = false;
else
  auto_lims = false;
end
meaned( 'epochs' ) = epoch;
if ( ~isempty(strfind(base_save_path, 'coherence')) )
  c = meaned.combs( {'regions', 'trialtypes', 'drugs'} );
else c = meaned.combs( {'outcomes', 'trialtypes', 'drugs'} );
end
for i = 1:size(c, 1)
  one_reg = meaned.only( c(i, :) );
  if ( auto_lims )
    clims = lims.only( c(i, :) );
    clims = clims.data;
  end
  one_reg.spectrogram( {'outcomes', 'regions', 'monkeys'} ...
    , 'frequencies', [0 100] ...
    , 'clims', clims ...
    , 'shape', shape ...
    , 'fullScreen', true ...
    , 'time', time_limits ...
    , 'rectangle', [] ...
  );
  savestr = strjoin( {'all__monks', strjoin(c(i,:), '_'), epoch}, '_' );
  full_save_path = fullfile( base_save_path, savestr );
  saveas( gcf, [full_save_path '.epsc'], 'epsc' );
  saveas( gcf, [full_save_path, '.svg'], 'svg' );
%   print( gcf, '-depsc2', [full_save_path '.eps'] );
  saveas( gcf, [full_save_path '.png'], 'png' );
  savefig( gcf, [full_save_path '.fig'] );
end

end

function obj = manipulation__pro_v_anti( obj )

obj = obj.subtract_across_mult( {'self', 'both', 'selfMinusBoth'} ...
  , {'other', 'none', 'otherMinusNone'} );

end

function obj = manipulation__received_v_forgone( obj )
 
forgone = obj.only( {'other', 'none'} );
received = obj.only( {'self', 'both'} );
forgone = forgone.mean_across( 'outcomes' );
forgone( 'outcomes' ) = 'forgone';
received = received.mean_across( 'outcomes' );
received( 'outcomes' ) = 'received';
obj = forgone.append( received );

end

% {[-50, 200, 30, 50], [-250, 0, 4, 20], [50, 300, 4, 20]}

function lims = get_limits( obj, within )

lims = Container();

if ( isempty(within) )
  enumed = { obj };
else
  enumed = obj.enumerate( within );
end

for i = 1:numel( enumed )
  current = enumed{i};
  data = current.data;
  maxed = max( data(:) );
  mined = min( data(:) );
  current = current.collapse_non_uniform();
  current = current(1);
  current.data = [ mined, maxed ];
  lims = lims.append( current );
end

end