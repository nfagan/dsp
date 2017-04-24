function bad_rows = dsp__identify_bad_sites( obj, fields )

within = { 'days', 'channels', 'regions' };
c = allcomb( obj.uniques(fields) );
[objs, ~, cmbs] = obj.enumerate( within );

bad_rows = {};

for i = 1:numel(objs)
  current = objs{i};
  for k = 1:size(c, 1)
    are_present = any( current.where(c(k, :)) );
    if ( ~are_present )
      bad_site = current.flat_uniques( within );
      bad_rows(end+1, :) = bad_site;
      break;
    end
  end
end

end