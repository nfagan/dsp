%   DSP__REFORMAT_CHANNELS_AND_REGIONS -- When loading in 32-channel data,
%     the 'regions' field of the loaded object actually contains the
%     channel-name of the associated signal (not the region per se). This
%     function corrects the 'regions' field of the object by assigning the
%     correct region to the associated channel names / numbers, and then
%     copies the original 'regions' field to a new 'channels' field.
%
%     Define the relationship between channel names and regions in `map`.
%     Each top-level fieldname of `map` is a region; each top-level field
%     is a struct with fields `prefixes` and `nums`. These fields are both
%     cell-arrays -- each `prefixes(i)` is prepended before each number in
%     `nums(i)` to create search strings. E.g., if map.bla.prefixes = {'fp'},
%     and map.bla.nums = {[9, 10]}, then the resulting search strings
%     corresponding to region 'bla' will be { 'fp09', 'fp10' };

function obj = dsp__reformat_channels_and_regions(obj)

assert( isa(obj, 'SignalObject'), ...
  'Input must be a SignalObject; was a ''%s''', class(obj) );

obj = obj.addfield('channels');
channels = obj('regions');

map = struct( ...
  'acc', struct('prefixes', {{'fp'}}, 'nums', {{17:32}}), ...
  'bla', struct('prefixes', {{'fp'}}, 'nums', {{9}}), ...
  'ref', struct('prefixes', {{'fp'}}, 'nums', {{10}}) ...
);

regions = fieldnames( map );

for i = 1:numel(regions)
  prefixes = map.(regions{i}).prefixes;
  for j = 1:numel(prefixes)
    current_nums = map.(regions{i}).nums{j};
    searches = cell( size(current_nums) );
    for k = 1:numel(current_nums)
      search_num = num2str( current_nums(k) );
      if ( current_nums(k) < 10 ), search_num = [ '0' search_num ]; end;
      searches{k} = [ prefixes{j} search_num ];
    end
    ind = obj.where( searches );
    obj( 'regions', ind ) = regions(i);
  end
end

obj('channels') = channels;

end