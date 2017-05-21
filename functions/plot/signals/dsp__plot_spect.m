function dsp__plot_spect( obj, plots_are, panels_are, savepath, varargin )

c = obj.combs( plots_are );
formats = { 'epsc', 'svg', 'png', 'fig' };

for i = 1:size(c, 1)
  extr = obj.only( c(i, :) );
  extr.spectrogram( panels_are, varargin{:} );
  filename = strjoin( c(i, :), '_' );
  
  for k = 1:numel(formats)
    full_save = fullfile( savepath, formats{k} );
    if ( exist(full_save, 'dir') ~= 7 ), mkdir(full_save); end;
    file = fullfile( full_save, [filename '.' formats{k}] );
    saveas( gcf, file, formats{k} );
  end
end

end