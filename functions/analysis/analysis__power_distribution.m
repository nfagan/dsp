function analysis__power_distribution(power)

calc_power = power.only({'other','acc'});

calc_power = combine_across_days(calc_power);

time_limits = [300 700];
freq_limits = [70 100];

freqs = [0:200];
times = [-1000:50:1000];

start_freq = find(freqs == freq_limits(1));
end_freq = find(freqs == freq_limits(2));

start_time = find(times == time_limits(1));
end_time = find(times == time_limits(2));

store = []; stp = 1;

n_trials = min( cellfun(@(x) size(x{1}, 2), calc_power.data(:,1)) );


for i = 1:n_trials
    
    one_trial = calc_power.onetrial(i);
    
    days = unique(one_trial('days'));
    
    for k = 1:numel(days)
        
        one_day = one_trial.only(days{k});
        data = one_day.data;
        
        data = data{1}(start_freq:end_freq, start_time: end_time);
        
        store(stp) = mean(mean(data));
%         store(stp) = max(max(data));
            
        stp = stp + 1;
        
    end
    
end

ind = find(store > 2);

for i = 1:numel(ind)
    
    one_trial = calc_power.onetrial(ind(i));
    one_trial = one_trial.addfield('trials');
    one_trial('trials') = ['trials__' num2str(ind(i))];
    
    plot__dsp_spect(one_trial);
end

% figure;
% histogram(store, 200);

end

function store_power = combine_across_days(power)

within = power.fieldnames('-except','days');

indices = power.getindices(within);

for i = 1:numel(indices)
    extr = power(indices{i});
    
    data = extr.data;
    
    first_loop = true;
    
    fixed_data = {};
    for k = 1:numel(data)        
        if ( first_loop )
            fixed_data = data{k}; first_loop = false; continue;
        end        
        for j = 1:numel(data{1})
            fixed_data{j} = [fixed_data{j} data{k}{j}];
        end
    end
    
    extr = extr.collapse('days');
    
    extr = extr(1); extr.data = {fixed_data};
    
    if ( i == 1 ); store_power = extr; continue; end;
    
    store_power = [store_power; extr];
end

end