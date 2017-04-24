function dsp__apply_limits( h, kind, lims )

axes = findobj( h, 'type', 'axes' );
assert( numel(axes) > 0, 'No axes found.' );
set( axes, kind, lims );

end