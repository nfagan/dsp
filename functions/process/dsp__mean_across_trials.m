function obj = dsp__mean_across_trials( obj )

data = obj.data;

for i = 1:numel(data)
  data{i} = cell2mat( cellfun(@(x) mean(x, 2), data{i}, 'un', false) );
end

obj.data = data;

end