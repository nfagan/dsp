function plot__spectrogram(obj,varargin)

params = struct(...
    'clims',[], ...
    'logTransform', false, ...
    'smooth',false, ...
    'addGaussian',true, ...
    'timeSeries', [], ...
    'fromTo', [], ...
    'freqLimits', [0 200], ...
    'savePlot', false, ...
    'savePath', [], ...
    'filetype',   'epsc', ...
    'xLabel', 'Time (ms)', ...
    'yLabel', [], ...
    'title', [] ...
);

params = paraminclude('Params__signal_processing.mat',params);
params = parsestruct(params,varargin);

%   - parse inputs
%   params

time_series = params.timeSeries;
log_transform = params.logTransform;
do_blur = params.addGaussian;
do_smoothing = params.smooth;
clims = params.clims;
freqs = params.freqs;
freq_limits = params.freqLimits;
save_plot = params.savePlot;
save_path = params.savePath;
from_to = params.fromTo;
filetype = params.filetype;

%   - account for empty inputs

if isempty(time_series)
    time_series = -1000:50:1000;
end

%   data

data = obj.data;
data = data{1};

%   - truncate data based on max_freq

ind = freqs <= freq_limits(2) & freqs >= freq_limits(1);
freqs = freqs(ind); data = data(ind,:);

%   - reformat freqs to span the column-width of data

freqs = repmat(freqs',1,size(data,2));

freqs = flipud(freqs); data = flipud(data);

%   - remove out of time-bounds data based on <from_to>
%       and add index of 0 so that 0 is always labeled

if ~isempty(from_to)
    from = find(time_series == from_to(1));
    to = find(time_series == from_to(2));
    
    if isempty(from) || isempty(to)
        error('Couldn''t find the start or end time');
    end
    
    time_series = time_series(from:to);
    data = data(:,from:to);
    freqs = freqs(:,from:to);
    
    %   zero index
    
    zero = find(time_series == 0);
else zero = 1;
end

%   - optionally log-transform the data

if log_transform
    data = 10.*log10(data);
end

%   - optionally smooth and/or gauss filter

if do_smoothing
    for i = 1:size(data,2)
        data(:,i) = smooth(data(:,i));
    end
end

if do_blur
    data = imgaussfilt(data,2);
end

%   - plot

figure;
if ~isempty(clims);
    h = imagesc(freqs,'CData',data,clims);
else h = imagesc(freqs,'CData',data);
end

colormap('jet');
d = colorbar;

%   - labeling

%   freqs

label_freqs = repmat({''},size(freqs,1),1);
for k = 1:10:size(freqs,1);
    label_freqs{k} = num2str(round(freqs(k,1)));
end

set(gca,'ytick',1:length(label_freqs));
set(gca,'yticklabel',label_freqs);

%   time

label_time = repmat({''},1,length(time_series));
for k = 1:10:length(time_series)
    label_time{k} = num2str(time_series(k));
end

if ~isempty(zero)
    label_time(zero) = {'0'};
end

set(gca,'xtick',1:length(label_time));
set(gca,'xticklabel',label_time);

%   x and y labels

if ~isempty(params.xLabel)
    xlabel(params.xLabel);
end

if ~isempty(params.yLabel)
    ylabel(d,params.yLabel);
end

%   title

if ~isempty(params.title)
    title(params.title);
end

%   - save output

if save_plot
    saveas(gcf,save_path,filetype);
end


end