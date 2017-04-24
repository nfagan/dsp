function flattened = dsp__flatten_measure( obj )

data = obj.data;
flattened = DataObject();
for i = 1:numel(data)
  fprintf( '\n ! dsp__flatten_measure: Processing %d of %d', i, numel(data) );
  current = data{i};
  n_times = numel( current );
  n_trials = size( current{1}, 2 );
  
  current = cell2mat( cellfun(@(x) x', current(:), 'un', false) );
  trials = repmat( (1:n_trials)', n_times, 1 );
  times = repmat( (1:n_times)', n_trials, 1 );
  
  trials = arrayfun( @(x) ['trial__' num2str(x)], trials, 'un', false );
  times = arrayfun( @(x) ['times__' num2str(x)], times, 'un', false );
  
  labs = obj(i);
  labs = replabels( labs, size(trials,1) );
  labs.times = times;
  labs.trials = trials;
  tic;
  flattened = flattened.append( SignalObject(DataObject(current, labs), obj.fs, obj.time) );
  toc;
end


end


%   labs.times = 1:numel(current);
%   labs.trials = 1:size( current{1}, 2 );
%   
%   fields = fieldnames( labs );
%   for k = 1:numel(fields)
%     labs.(fields{k}) = arrayfun( @(x) [fields{k} '__' num2str(x)] ...
%       , labs.(fields{k}), 'un', false );
%   end
%   