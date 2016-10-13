classdef SignalObject < DataObject
    
    properties (Access = public)
       fs;
       time;
    end
    
    methods
        function obj = SignalObject(data_struct, fs, time)
            obj = obj@DataObject(data_struct);
            obj.fs = fs;
            if nargin > 2
                obj.time = time;
            end
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
            obj = SignalObject__downsample(obj,new_fs); obj.fs = new_fs;
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
        
        %   - filter
        
        function obj = filter(obj,varargin)
           obj = SignalObject__filter(obj,varargin{:}); 
        end
        
        %   - remove line noise
        
        function obj = rmline(obj,varargin)
            obj = SignalObject__rmline(obj,varargin{:});
        end
        
        %   - process -- filter, rmline, window
        
        function obj = process(obj,w_step,w_size)
            obj = window(rmline(filter(obj)),w_step,w_size);
        end
        
        %{
            operations
        %}
        
        function obj = minus(obj,b)
            obj = SignalObject__subraction(obj,b);
        end
        
        function obj = windowmean(obj)
            obj = SignalObject__windowmean(obj);
        end
        
        function unwindowed = windowconcat(obj)
            unwindowed = SignalObject__windowconcat(obj);
        end
        
        function obj = vertcat(obj,varargin)
            catted = vertcat@DataObject(obj,varargin{:});
            obj = SignalObject(catted,obj.fs,obj.time);
        end
        
        %{
            subscript reference / assignment
        %}
        
        %   - reference
        
        function obj = subsref(obj,varargin)
            fs = obj.fs; time = obj.time; %#ok<PROPLC>
            obj = subsref@DataObject(obj,varargin{:});
            if isa(obj,'DataObject')
                obj = SignalObject(obj,fs,time); %#ok<PROPLC>
            end
        end
        
        %   - assignment
        
        function obj = subsasgn(obj,varargin)
            s = varargin{1};
            if strcmp(s.type,'.') && any(strcmp(properties(obj),s.subs))
                obj.(s.subs) = varargin{2}; return;
            end
            fs = obj.fs; time = obj.time; %#ok<PROPLC>
            obj = subsasgn@DataObject(obj,varargin{:});
            if isa(obj,'DataObject')
                obj = SignalObject(obj,fs,time); %#ok<PROPLC>
            end
        end
        
        %   label handling
        
        function out = remove(obj, labels)
            out = remove@DataObject(obj, labels);
            out = SignalObject(out, obj.fs, obj.time);
        end
        
        %{
            helpers
        %}
        
        function obj = onetrial(obj,varargin)
            obj = SignalObject__onetrial(obj,varargin{:});
        end
            
    end
    
    %{
        static methods
    %}
    
    methods (Static)
        
        %{
            static signal manipulation methods
        %}
        
        function varargout = exclude(objs,limits)
            objs = SignalObject__exclude(objs,limits);
            varargout = cell(size(objs));
            for i = 1:numel(objs)
                varargout(i) = objs(i);
            end
        end
    end
    
end