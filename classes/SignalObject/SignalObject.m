classdef SignalObject < DataObject
    
    properties (Access = public)
       fs;
    end
    
    methods
        function obj = SignalObject(data_struct, fs)
            obj = obj@DataObject(data_struct);
            obj.fs = fs;
        end
        
        %{
            signal manipulation
        %}
        
        %   - windowing
        
        function obj = window(obj,step,w_size)
            obj = SignalObject__window(obj,step,w_size);
        end
        
        %   - downsampling
      
        function obj = downsample(obj,new_fs)
            obj = SignalObject__downsample(obj,new_fs);
        end
            
    end
    
end