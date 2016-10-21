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
%     subfolder = 'raw_coherence_excluded';
    subfolder = 'targetacquire/subtracted_coherence_antiVPro_choice';
end

if nargin < 2
    plotdirectory = fullfile(pathfor('secondGrantPlots'),'102016');
end

within = data.label_fields;
[indices, combs] = getindices(data,within);

%   use append to add an identifier / comment to the programatically
%   generated filename

append = '';

%   generate color limits automatically

clims = autoscaler(data);

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
        'fromTo',       [-250 250], ...
        'timeSeries',   data.time, ...
        'freqs',        [0:200], ...
        'savePlot',     true, ...
        'logTransform', false, ...
        'savePath',     filepath,...
        'filetype',     'epsc', ...
        'clims',        [-.025 .025], ...
        'xLabel',       sprintf('Time (ms) from %s',epoch), ...
        'yLabel',       'Normalized power', ...
        'title',        convert_to_title(filename) ...
        );
end

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

%{
    get appropriate color limits automatically
%}

function clims = autoscaler(obj)

global_min = min( obj.cellfun(@(x) mean(mean(x)) - 2.5*mean(std(x))) );
global_max = max( obj.cellfun(@(x) mean(mean(x)) + 2.5*mean(std(x))) );

clims = [global_min global_max];

end