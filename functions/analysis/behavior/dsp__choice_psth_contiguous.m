function psth = dsp__choice_psth_contiguous( behav, n, align_on_outcome )

if ( nargin < 3 ), align_on_outcome = 'prosocial'; end;

objs = behav.enumerate( 'days' );
choice_psth = nan( 1e3, n );
stp = 1;
for i = 1:numel(objs)
  current = objs{i};
  trial_ids = current.trial_ids;
  pro = current.where( align_on_outcome );  
  pro_ind = find( pro, 1, 'first' );
  pro_inds = find( pro );
  while ( pro_ind + n <= numel(pro) )
    
    is_contiguous = all( diff(trial_ids(pro_ind:pro_ind+n-1)) == 1 );
    if ( ~is_contiguous )
      next = pro_ind+n;
      offsets = pro_inds - next;
      pro_ind = pro_inds( find(offsets >= 0, 1, 'first') );
      continue;
    end
    
    choice_psth(stp, :) = pro( pro_ind:pro_ind+n-1 );
    stp = stp + 1;
    next = pro_ind+n;
    offsets = pro_inds - next;
    pro_ind = pro_inds( find(offsets >= 0, 1, 'first') );
  end
  
end

nans = any( isnan(choice_psth), 2 );
% assert( ~all(nans), 'None were contiguous.' );

choice_psth = choice_psth( ~nans, : );
avged = mean( choice_psth, 1 );

psth = behav.collapse_non_uniform();
psth = psth(1);
psth.data = avged;

end