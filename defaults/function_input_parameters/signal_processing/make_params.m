%{
    Define as many paramaters as you want in this file. Then call
    paraminclude(<filename>) to add the params struct to the function
%}


params = struct(...
    'freqs',[0 200], ...
    'maxFreq', 200, ...
    'method','periodogram', ...
    'nMultitapers',4 ...
);

subfolder = 'signal_processing';
filename = 'Params__signal_processing.mat';

folder = fullfile(pathfor('parameters'),subfolder);

save(fullfile(folder,filename),'params');
