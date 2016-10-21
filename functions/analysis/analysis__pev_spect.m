function new_obj = analysis__pev_spect(obj)

time_windows = [-1000:50:1000-150];
time_windows(2,:) = [-850:50:1000];

% time_windows = [-1000:150:1000-150];
% time_windows(2,:) = [-850:150:1000];

time_windows = time_windows';

freq_windows = [0:10:110];
freq_windows(2,:) = [10:10:120];
freq_windows = freq_windows';

first_loop = true; stp = 1;

for i = 1:size(time_windows, 1)
    for k = 1:size(freq_windows, 1)
        fprintf( '\n%d of %d', stp, size(time_windows,1) * size(freq_windows,1) );
        
        out = analysis__mean_within_time_and_freq( obj, time_windows(i,:), freq_windows(k,:) );
        
%         r2 = correlate_size_vs_power(out);
        r2 = correlate_outcome_betas(out);
        
        if ( first_loop )
            data = cell( count(r2,1), 1 );
            data = cellfun(@(x) zeros( size(freq_windows,1), size(time_windows,1) ),...
                data, 'UniformOutput', false);
            first_loop = false;
        end
        
        for j = 1:count(r2,1)
            data{j,1}(k, i) = r2.data(j);
        end
        
        stp = stp + 1;
    end
    
    if ( i == 1 ); new_time = out.time; continue; end;
    
    new_time = [new_time out.time];
end

new_obj = SignalObject( DataObject(data, r2.labels), obj.fs, new_time );

end

function [all_mags, coded_mags] = get_correlation_matrix(obj, make_vector)

mags = unique( obj('magnitudes') );
days = unique( obj('days') );

all_mags = nan( numel(days), numel(mags) );
for k = 1:numel(days)
    for j = 1:numel(mags)
        permag = obj.only({mags{j}, days{k}});
        if isempty(permag); continue; end;
        all_mags(k,j) = permag.data;
    end
end

coded_mags = zeros( size(all_mags) );

mag_map = struct('low', 1, 'medium', 2, 'high', 3);

for j = 1:numel(mags)
    coded_mags(:,j) = mag_map.(mags{j});
end

if strcmp(make_vector, 'vectorize');
    
    all_mags = reshape(all_mags, [numel(all_mags) 1]);
    coded_mags = reshape(coded_mags, [numel(coded_mags) 1]);

end

end

function store_r2 = correlate_size_vs_power(obj)

within = obj.fieldnames('-except', {'magnitudes', 'days'});
indices = obj.getindices(within);

for i = 1:numel(indices)
    extr = obj(indices{i});
    mags = unique( extr('magnitudes') );
    days = unique( extr('days') );
    
    all_mags = nan( numel(days), numel(mags) );
    for k = 1:numel(days)
        for j = 1:numel(mags)
            permag = extr.only({mags{j}, days{k}});
            if isempty(permag); continue; end;
            all_mags(k,j) = permag.data;
        end
    end
    
    nan_ind = sum( isnan(all_mags), 2 ) >= 1;
    all_mags = all_mags(~nan_ind,:);
    
    coded_mags = zeros( size(all_mags) );
    
    mag_map = struct('low', 1, 'medium', 2, 'high', 3);

    for j = 1:numel(mags)
        coded_mags(:,j) = mag_map.(mags{j});
    end
    
    all_mags = reshape(all_mags, [numel(all_mags) 1]);
    coded_mags = reshape(coded_mags, [numel(coded_mags) 1]);
    
    r = corr(coded_mags, all_mags);
    
    r2 = r^2;
    
    to_label = extr(1);
    to_label = to_label.collapse({'days', 'magnitudes'});
    
    r2 = SignalObject( DataObject(r2, to_label.labels), obj.fs, obj.time );
    
    if ( i == 1 ); store_r2 = r2; continue; end;
    
    store_r2 = [store_r2; r2];
end

end

function store_r2 = correlate_outcome_betas(obj)

within = obj.fieldnames('-except', {'outcomes', 'days', 'magnitudes'});
indices = obj.getindices(within);

first_loop = true;

for i = 1:numel(indices)
    extr = obj(indices{i});
    pairs = extr.pairs('outcomes');
    
    for k = 1:size(pairs, 1)
        first_outcome = extr.only(pairs{k,1});
        sec_outcome = extr.only(pairs{k,2});
       
        [first, first_code] = get_correlation_matrix(first_outcome, 'no vector');
        [second, sec_code] = get_correlation_matrix(sec_outcome, 'no vector');
       
        nan_ind = sum( isnan([first second]), 2 ) >= 1;
       
        first(nan_ind,:) = [];
        second(nan_ind,:) = [];
        first_code(nan_ind,:) = [];
        sec_code(nan_ind,:) = [];
       
        first_fit = zeros(1, size(first,1));
        sec_fit = zeros( size(first_fit) );
        
        for j = 1:size(first,1)
            fitted = polyfit(first_code(j,:), first(j,:), 1);
            first_fit(j) = fitted(1);
            fitted = polyfit(sec_code(j,:), second(j,:), 1);
            sec_fit(j) = fitted(1);
        end
       
        r = corr(first_fit', sec_fit');

        r2 = r^2;

        to_label = first_outcome(1);
        to_label = to_label.collapse({'days', 'magnitudes'});
        to_label('outcomes') = [pairs{k,1} '_' pairs{k,2}];

        r2 = SignalObject( DataObject(r2, to_label.labels), obj.fs, obj.time );

        if ( first_loop ); store_r2 = r2; first_loop = false; continue; end;

        store_r2 = [store_r2; r2];
    end
        
end

end



%         for j = 1:count(out, 1)
%             data{j}{i}(k) = out.data(j);
%         end

%     new_obj = SignalObject( DataObject(data, r2.labels), obj.fs, out.time );
%     
%     if ( i == 1 ); store_objs = new_obj; continue; end;
%     
%     store_objs = [store_objs; new_obj];