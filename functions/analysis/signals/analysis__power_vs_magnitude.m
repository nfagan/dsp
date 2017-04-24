function analysis__power_vs_magnitude(obj, time, freqs)

params = paraminclude('Params__signal_processing');

time_markers = 1:numel(obj.time);
start_time = time_markers(obj.time == time(1));
end_time = time_markers(obj.time == time(2));

assert( all( [~isempty(start_time), ~isempty(end_time)] ), 'Could not find start or end time' );

all_freqs = params.freqs;
freq_markers = 1:numel(all_freqs);

start_freq = freq_markers(all_freqs == freqs(1));
end_freq = freq_markers(all_freqs == freqs(2));

assert( all( [~isempty(start_freq), ~isempty(end_freq)] ), 'Could not find start or end freq' );

within = obj.label_fields;
within = within( ~strcmp(within, 'magnitudes') );

indices = obj.getindices(within);

for i = 1:numel(indices)
    
    extr = obj(indices{i});
    
end


end