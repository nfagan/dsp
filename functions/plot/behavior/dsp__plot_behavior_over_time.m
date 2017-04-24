function dsp__plot_behavior_over_time( measure, n_bins, limits, pl )

if ( nargin < 4 )
  pl = ContainerPlotter();
  pl.default();
  pl.params.add_ribbon = true;
  % pl.params.error_function = @std;
  pl.params.x_lim = [-1/n_bins 1];
  pl.params.shape = [2 1];
  pl.params.x = 0:1/n_bins:1-1/n_bins;
  pl.params.add_legend = true;
  pl.params.x_label = { 'Percent of trials within Pre and Post' };
  pl.params.order_by = { 'pre', 'post' };
  pl.params.full_screen = true;
  pl.params.y_lim = limits;
else pl.params.y_lim = limits;
end
inds = measure.get_indices( {'monkeys', 'outcomes'} );
for i = 1:numel(inds)
  current = measure.keep( inds{i} );
  pl.plot( current, 'administration', {'outcomes', 'drugs', 'monkeys'} );
  outs = unique( current('outcomes') );
  monks = unique( current('monkeys') );
  file_name = strjoin( [outs(:); monks(:)], '_' );
  saveas( gcf, file_name, 'png' );
  saveas( gcf, file_name, 'epsc' );
end

end