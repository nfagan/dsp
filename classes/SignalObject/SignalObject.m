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
        
        %{
            signal processing
        %}
        
        %   - raw power
        
        function [pow, freqs] = raw_power(obj,varargin)
            [pow, freqs] = SignalObject__raw_power(obj,varargin{:});
        end
        
        %   - normalized power
        
        function [pow, freqs] = norm_power(obj,varargin)
            [pow, freqs] = SignalObject__norm_power(obj,varargin{:});
        end
        
        %   - coherence
        
        function [coh, freqs] = coherence(obj,varargin)
            [coh, freqs] = SignalObject__coherence(obj,varargin{:});
        end
        
        %{
            overloaded operations
        %}
        
        function obj = minus(obj,b)
            obj = SignalObject__subraction(obj,b);
        end
        
        %{
            subscript reference / assignment
        %}
        
        %   - reference
        
        function obj = subsref(obj,varargin)
            fs = obj.fs; %#ok<PROPLC>
            obj = subsref@DataObject(obj,varargin{:});
            if isa(obj,'DataObject')
                obj = SignalObject(obj,fs); %#ok<PROPLC>
            end
        end
        
        %   - assignment
        
        function obj = subsasgn(obj,varargin)
            fs = obj.fs; %#ok<PROPLC>
            obj = subsasgn@DataObject(obj,varargin{:});
            if isa(obj,'DataObject')
                obj = SignalObject(obj,fs); %#ok<PROPLC>
            end
        end
            
    end
    
end