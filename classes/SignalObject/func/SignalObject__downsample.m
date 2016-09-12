function obj = SignalObject__downsample(obj,new_fs)
    fs = obj.fs;

    factor = fs / new_fs;

    if factor < 1
        error(['New sampling rate must be lower than current sampling' ...
            , ' rate: %d'],fs);
    end

    if floor(factor) ~= factor
        error(['New sampling rate must be an integer factor of the' ...
            , ' old sampling rate'], fs);
    end

    if strcmp(obj.dtype,'cell')
        error('Cannot downsample windowed signals.');
    end

    obj.data = downsample(obj.data',factor)';
    obj.fs = new_fs;

end