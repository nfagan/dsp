function measure = dsp__n_minus_n(obj, n, restrictions)

if ( nargin < 3 || isempty(restrictions) )
  restrictions = [];
else 
  msg = 'Restrictions must be a cell array of cell arrays of strings';
  assert( iscell(restrictions), msg );
  assert( iscellstr(restrictions{1}), msg );
end

assert( ndims(obj.data) == 2, ... 
  'Take a mean across time and frequency before proceeding.' );
assert( ~any(isnan(obj.data)), 'Remove nans before proceeding.' );
[objs, inds, ~] = enumerate( obj, {'sites', 'days'} );

current = nan( shape(obj, 1), 1 );
prev = nan( size(current) );
full_current_ind = false( shape(obj, 1), 1 );
full_prev_ind = false( size(full_current_ind) );

previous_object = Container();
current_object = Container();
previous_labels = SparseLabels();
current_labels = SparseLabels();

stp = 1;

for i = 1:numel(objs)
  fprintf( '\n %d of %d', i, numel(objs) );
  extr = objs{i};
  extr = extr.full();
  trial_ids = extr.trial_ids;
  for k = 1:numel(trial_ids)
%   while ( ~isempty(trial_ids) )
    first = trial_ids(k);
    next_index = trial_ids == first+n;
    exists = any( next_index );
    if ( exists )
      prev_ind = extr.trial_ids == first;
      current_ind = extr.trial_ids == first+n;
      if ( ~isempty(restrictions) )
        prev_obj = extr.keep( prev_ind );
        curr_obj = extr.keep( current_ind );
        if ( ~isempty(restrictions{1}) )
          contains_restrictions1 = all( prev_obj.contains(restrictions{1}) );
        else contains_restrictions1 = true;
        end
        if ( ~isempty(restrictions{2}) )
          contains_restrictions2 = all( curr_obj.contains(restrictions{2}) );
        else contains_restrictions2 = true;
        end
        proceed = contains_restrictions1 && contains_restrictions2;
      else
        proceed = true;
      end
      if ( proceed )
        prev(stp) = extr.data( prev_ind );
        current(stp) = extr.data( current_ind );
        
        previous_labels = previous_labels.append( extr(prev_ind).labels );
        current_labels = current_labels.append( extr(current_ind).labels );
        
%         previous_object = previous_object.append( extr(prev_ind) );
%         current_object = current_object.append( extr(current_ind) );

        full_prev_ind( inds{i} ) = prev_ind | full_prev_ind( inds{i} );
        full_current_ind( inds{i} ) = current_ind | full_current_ind( inds{i} );

        assert( sum(full_current_ind) == stp );
        stp = stp + 1;
      end
    end
%     trial_ids(1) = [];
%     next_index(1) = true;
%     trial_ids(next_index) = [];
  end
end

nans = any( [isnan(current), isnan(prev)], 2 );
current(nans) = [];
prev(nans) = [];
% 
% current_cont = obj.keep( full_current_ind );
% prev_cont = obj.keep( full_prev_ind );
% current_cont.data = current;
% prev_cont.data = prev;

current_cont = Container( current, current_labels );
prev_cont = Container( prev, previous_labels );

current_cont = current_cont.sparse();
prev_cont = prev_cont.sparse();

current_cont = current_cont.add_field( 'trialset', 'current' );
prev_cont = prev_cont.add_field( 'trialset', 'previous' );
measure = current_cont.append( prev_cont );

end