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
        
        function data = windowed_data(obj, step, w_size)
            data = SignalObject__get_windowed_data(obj, step, w_size);
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
        
        function obj = subtract_across(obj, varargin)
            obj = SignalObject__subtract_across(obj, varargin{:});
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
        
        function obj = selecttime(obj, time)
            obj = SignalObject__select_time(obj, time);
            obj.time = time;
        end
        
        %   - take a mean of the analysis output within <freqs> and <time>
        
        function obj = timefreqmean(obj, time, freqs, varargin)
            obj = SignalObject__time_freq_mean(obj, time, freqs, varargin{:});
        end
        
        %   - take a mean within frequencies, across <time>
        
        function obj = timemean(obj, time, varargin)
            obj = SignalObject__time_mean(obj, time, varargin{:});
        end
        
        %   - take a mean within each time sample, across <freqs>
        
        function obj = freqmean(obj, bands, varargin)
            obj = SignalObject__freq_mean(obj, bands, varargin{:});
        end
        
        %   - recursively mean pairs of matrices in <field>, such that 
        %   the outputted <obj> has the same number of elements as one
        %   label in <field>
        
        function obj = meancollapse(obj, field)
            obj = SignalObject__meancollapse( obj, field );
        end
        
        %   - take a mean across a given field
        
        function [obj, errors] = meanacross(obj, varargin)
            [obj, errors] = SignalObject__mean_across(obj, varargin{:});
        end
        
        function obj = meanacrosspairs(obj, label1, label2, varargin)
            obj = SignalObject__mean_across_pairs(obj, label1, label2, varargin{:});
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