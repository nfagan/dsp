function dsp__choice_string( behav )

outs = behav( 'outcomes' );
c = behav.combs( {'outcomes', 'trialtypes'} );
choice_ind = false( behav.shape(1), 1 );
outcome_ind = zeros( behav.shape(1), 1 );
for i = 1:size(c, 1)
  ind = behav.where( c(i, :) );
  if ( any(strcmp(c(i, :), 'choice')) )
    choice_ind( ind ) = true;
  end
  outcome_ind( ind ) = find( strcmp(outs, c(i, 1)) );
end

%%
colors = { 'r', 'g', 'b', 'y', 'm' };
xs = 1:size( choice_ind, 1 );
figure; hold on;
for i = 1:numel(outs)
  choice = choice_ind & outcome_ind == i;
  cued = ~choice_ind & outcome_ind == i;
  x_choice = xs( choice );
  x_cued = xs( cued );
  
  h(i) = plot( x_choice, ones(size(x_choice)), [colors{i}, '*'] );
  h1 = plot( x_cued, ones(size(x_cued)), 'k*' );
  
  set( h1, 'markersize', 1 );
  
end
set( h, 'markersize', 2 );
legend( h, outs );
xlim( [0, max(xs)] );

%%

return;

xs = 1:size( choice_ind, 1 );
figure;
hold on;
for i = 2:-1:1
  if ( i == 1 )
    choice_ind = ~choice_ind;
    color = 'k';
  else color = 'r';
  end
  x = xs( choice_ind );
  out = outcome_ind( choice_ind );
  h = plot( x, out, ['*' color] );
  set( h, 'markersize', 1 );
end

set( gca, 'ytick', 1:numel(outs) );
set( gca, 'yticklabels', outs );

end