classdef SignalPoint < DataPointObject
    
    properties
        fs;
        time = struct(...
            'from', NaN, ...
            'to',   NaN, ...
            'by',   NaN ...
        );
        window = struct(...
            'iswindowed', false, ...
            'step', NaN, ...
            'size', NaN ...
            )
    end
    
    methods 
        
        function obj = SignalPoint(data,labels,fs,time)
            obj = obj@DataPointObject(data,labels);
            
            SignalPoint.validate_time(time);
            SignalPoint.validate_fs(fs);
            
            obj.fs = fs;
            
            obj.time.from = time(1); 
            obj.time.to = time(2);
        end
        
        function obj = getwindowed(obj,step,w_size)
            obj = SignalPoint__getwindowed(obj,step,w_size);
        end
        
        function obj = refresh(obj)
            obj = SignalPoint(obj.data,obj.labels,obj.fs,[obj.time.from obj.time.to]);
        end
            
    end
    
    methods (Static)
        
        function validate_fs(fs)
            msg = '<fs> must be a single element, positive double';
            
            assert(isa(fs,'double'),msg);
            assert(sign(fs) == 1,msg);
        end
        
        function validate_time(time)
            msg = ['<time> must be a two-element array where the first-element' ...
                , ' is less than the second'];
            
            assert(isa(time,'double'),msg);
            assert(length(time) == 2,msg);
            assert(time(1) < time(2),msg);
        end
        
    end
    
end