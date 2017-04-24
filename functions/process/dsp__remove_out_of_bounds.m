function dsp__remove_out_of_bounds( signals, bounds )

assert( count(signals,1) == count(bounds,1), ['Dimensions must match between' ...
  , ' signals and bounds'] );

signal_data = signals.data;
bounds_data = bounds.data;

for i = 1:size(signal_data, 1)
  d = 10;
end

end