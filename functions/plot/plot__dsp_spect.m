%{

    plot__dsp_spect.m -- wrapper function to generate multiple plots from
    a SignalObject <data>. This function is essentially a script, and the
    purpose of formatting things this way is merely to avoid cluttering the
    global workspace. 

    <plotdirectory> specifies the outermost plotting folder. <subfolder>
    specifies a subfolder within <plotdirectory>.

    NOTE: it is assumed that each dataset in <data> is associated with a
    unique label set -- i.e., for each possible combination of labels
    in the object, there should only be one cell array identified by that
    particular combination. Only the first cell in <data.data> will be
    plotted in the call to plot__spectrogram()

%}

function plot__dsp_spect(data, plotdirectory, subfolder)

if nargin < 3
%     subfolder = 'subtracted_coherence_oxyMinusSal';
    subfolder = 'raw_coherence_excluded';
end

if nargin < 2
    plotdirectory = fullfile(pathfor('secondGrantPlots'),'101116');
end

within = data.label_fields;
[indices, combs] = getindices(data,within);

%   use append to add an identifier / comment to the programatically
%   generated filename

append = '';

for i = 1:length(indices)
    extr = data(indices{i});
    
    filename = create_identifiers(extr);
    
    if ~strcmp(append,''); filename = [filename append]; end
    
    filepath = fullfile( plotdirectory, subfolder, filename );
    
    %   get the epoch for the proper x label
    
    epoch = char( unique(extr('epochs')) );
    
    plot__spectrogram(extr,...
        'visible',      'off', ...
        'freqLimits',   [0 120], ...
        'fromTo',       [-300 700], ...
        'timeSeries',   data.time, ...
        'freqs',        [0:200], ...
        'savePlot',     true, ...
        'logTransform', false, ...
        'savePath',     filepath,...
        'filetype',     'png', ...
        'clims',        [0 .6], ...
        'xLabel',       sprintf('Time (ms) from %s',epoch), ...
        'yLabel',       'Normalized Power', ...
        'title',        convert_to_title(filename) ...
        );
end

% [-.03 .065

end

%{
    create a filename based on the unique labels in each label field of the
    <data> object
%}

function id = create_identifiers(obj)

fields = obj.label_fields;

for i = 1:numel(fields)
    labels = char( unique(obj(fields{i})) );
    
    if ( i == 1 ); id = labels; continue; end;
    
    id = sprintf('%s_%s', id, labels);
end

end

%{
    replace underscores with spaces
%}

function filename = convert_to_title(filename)

underscores = strfind(filename,'_');
filename(underscores) = ' ';

end




% pathchange('sheth');
% plotdirectory = fullfile(pathfor('plots'), '100516');
% pathchange('dsp');

% within = {'epochs','administration','trialtypes','outcomes'};
% within = {'subjects','regions','emotions'};

% append = '_subtract_by_mean_baseline_within_outcome';


% 
%     drug = 'na';
%     admin = 'na';
%     trial = 'na';
%     outcome = char(unique(extr('emotions')));
%     region = char(unique(extr('regions')));
%     epoch = char(unique(extr('subjects')));
    
%     drug =      char(unique(extr('drugs')));
%     admin =     char(unique(extr('administration')));
%     trial =     char(unique(extr('trialtypes')));
%     outcome =   char(unique(extr('outcomes')));
%     region =    char(unique(extr('regions')));
%     epoch =     char(unique(extr('epochs')));

%     filename = sprintf('%s_%s_%s_%s_%s_%s',drug,admin,epoch,region,trial,outcome);