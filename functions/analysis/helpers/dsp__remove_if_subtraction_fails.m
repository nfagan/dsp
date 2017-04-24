function new_obj = dsp__remove_if_subtraction_fails(obj, within, varargin)

objs = obj.enumerate( within );
new_obj = Container();
for i = 1:numel(objs)
  current = objs{i};
  try
    new_obj = new_obj.append( current.subtract_across(varargin{:}) );
  catch
    continue;
  end
end

end