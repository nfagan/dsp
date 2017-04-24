function dsp__plot_signal_measures_fnc()

% {'ztrans/without_errors_pre_and_post/common_averaged'}

combs = allcomb( { ...
    { 'non_common_averaged' } ...
  , { 'normalized_power_within_pre_post' } ...
  , { 'targacq' } ...
  , { 'pro_v_anti_per_drug' } ...
} );

% combs = allcomb( { ...
%     { 'non_common_averaged' } ...
%   , { 'coherence', 'normalized_power_within_pre_post' } ...
%   , { 'reward', 'targacq' } ...
%   , { 'pro_v_anti_oxy_minus_sal' } ...
% } );

base_load_path = fullfile( pathfor('ANALYSES'), '020317' );

is_z = false;
% is_drug = true;
limit_type = 'variable_limits';
day = '042217';

for i = 1:size( combs, 1 )
  meth = combs{i, 1};
  measure = combs{i, 2};
  epoch = combs{i, 3};
  kind = combs{i, 4};
  
  base_save_path = fullfile( pathfor('PLOTS'), day, 'signals', kind, limit_type );
  
  if ( ~isempty(strfind(kind, 'oxy')) || ~isempty(strfind(kind, 'drug')) )
    is_drug = true;
  else is_drug = false;
  end
  
  if ( isequal(measure, 'normalized_power') )
    switch ( epoch )
      case 'reward'
        switch ( kind )
          case 'pro_v_anti'
            clims = [ -.1 .05 ];
          case 'pro_minus_anti'
            clims = [ -.2 .01 ];
        end
      case 'targacq'
         switch ( kind )
          case 'pro_v_anti'
            clims = [ -.1 .06 ];
          case 'pro_minus_anti'
            clims = [ -.17 .01];
        end
      case 'targon'
         switch ( kind )
          case 'pro_v_anti'
            clims = [ -.06 .04];
          case 'pro_minus_anti'
            clims = [ -.15 .1 ];
        end
    end
  end
  
  if ( isequal(measure, 'normalized_power_within_pre_post') )
     switch ( epoch )
      case 'reward'
        switch ( kind )
          case 'pro_v_anti'
            clims = [ -.012 .015 ];
          case 'pro_minus_anti'
            clims = [];
        end
      case 'targacq'
       switch ( kind )
         case 'pro_v_anti'
          clims = [ -.004 .01 ];
         case 'pro_minus_anti'
           clims = [ -.002 .012 ];
         case 'pro_v_anti_oxy_minus_sal'
           clims = [ -.015 .015 ];
         case 'pro_minus_anti_oxy_minus_sal'
           clims = [ -.015 .015 ]; 
        end
      case 'targon'
         switch ( kind )
          case 'pro_v_anti'
            clims = [ -.004 .01 ];
          case 'pro_minus_anti'
            clims = [ -.002 .012 ];
           case 'pro_v_anti_oxy_minus_sal'
             clims = [ -.015 .015 ];
           case 'pro_minus_anti_oxy_minus_sal'
             clims = [ -.015 .015 ];
        end
    end
  end
  
  if ( isequal(measure, 'coherence') )
    switch ( epoch )
      case 'reward'
        switch ( kind )
          case 'pro_v_anti'
            clims = [ -.012 .015 ];
          case 'pro_minus_anti'
            clims = [];
        end
      case 'targacq'
       switch ( kind )
         case 'pro_v_anti'
%           clims = [ -.004 .01 ];
          clims = [ -8e-3 10e-3 ];
         case 'pro_minus_anti'
           clims = [ -.002 .012 ];
         case 'pro_v_anti_oxy_minus_sal'
           clims = [ -.015 .015 ];
         case 'pro_minus_anti_oxy_minus_sal'
           clims = [ -.015 .015 ]; 
        end
      case 'targon'
         switch ( kind )
          case 'pro_v_anti'
            clims = [ -.004 .01 ];
          case 'pro_minus_anti'
            clims = [ -.002 .012 ];
           case 'pro_v_anti_oxy_minus_sal'
             clims = [ -.015 .015 ];
           case 'pro_minus_anti_oxy_minus_sal'
             clims = [ -.015 .015 ];
        end
    end
  end
  
  
%   if ( isequal(measure, 'normalized_power') )
%     clims = [-.3 .3];
%   else clims = [-8e-3 8e-3];
%   end
  
%   clims = [-.15 .1];
%   clims = [-.35 .35];
%   clims = [];
  clims = [-.15 .2];
  full_load_path = fullfile( base_load_path, meth, measure, epoch );
  if ( is_z && ~isequal(measure, 'coherence') )
    full_load_path = fullfile( full_load_path, 'per_outcome' ); 
  end
  fuller_save_path = fullfile( base_save_path, meth, measure, epoch );
  if ( exist(fuller_save_path, 'dir') ~= 7 ), mkdir(fuller_save_path); end;
  
  dsp__plot_spect_across_monks( full_load_path, fuller_save_path, epoch, clims, kind, is_z, is_drug );
end

%%
commandwindow