function h = dsp__load_and_apply_limits( filename, kind, lims )

h = openfig( filename );
dsp__apply_limits( h, kind, lims );

end