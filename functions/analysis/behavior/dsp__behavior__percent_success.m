function perc = dsp__behavior__percent_success( obj, within )

assert( isa(obj, 'Container'), 'Input must be a Container; was a ''%s''' ...
  , class(obj) );
inds = obj.get_indices( within );
perc = Container();
collapse_cats = setdiff( obj.field_names(), within );
for i = 1:numel(inds)
  extr = obj( inds{i} );
  n_errors = shape( extr.only('errors'), 1 );
  n_tot = shape( extr, 1 );
  percent = n_errors / n_tot;
  extr = extr.collapse( collapse_cats );
  extr = extr(1);
  extr.data = percent;
  perc = perc.append( extr );
end

end