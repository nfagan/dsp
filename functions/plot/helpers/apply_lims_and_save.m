function h = apply_lims_and_save( filename, kind, lims, varargin )

params = struct( ...
    'formats', {{ 'eps', 'svg', 'png' }} ...
  , 'append', [] ...
);
params = parsestruct( params, varargin );

h = dsp__load_and_apply_limits( filename, kind, lims );

if ( ~isempty(params.append) )
  filename = sprintf( '%s_%s', filename, params.append );
end

for i = 1:numel(params.formats)
  saveas( gcf, [filename '.' params.formats{i}], params.formats{i} );
end

end