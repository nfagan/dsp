classdef SignalObject
    
    properties (Access = public)
       original;
       signals;
       fs;
    end
    
    methods
        function obj = SignalObject(data_struct, fs)
            if isa(data_struct,'DataObject')
                obj.signals = data_struct;
            else obj.signals = DataObject(data_struct);
            end
            
            obj.fs = fs;
            obj.original.signals = obj.signals;
            obj.original.fs = obj.fs;
        end
        
        %{
            object lifespan functions
        %}
        
        function obj = reset(obj)
            obj.signals = obj.original.signals;
            obj.fs = obj.original.fs;
        end
        
        %{ 
            reference, assignment, equality
        %}
        
        %   - eq
        
        function [ind, field] = eq(obj,varargin)
            [ind,field] = eq(obj.signals, varargin{:});
        end
        
        %   - reference
        
        function obj = subsref(obj,varargin)
            s = varargin{1};
            
            if strcmp(s(1).type,'()')
                out = subsref(obj.signals,s(1));
                if isa(out,'DataObject')
                    obj.signals = out;
                else
                    obj = out;
                end
                return;
            end
            
            if strcmp(s(1).type,'.');
                obj = obj.(s(1).subs);
            end
            
            s(1) = [];
            if isempty(s)
                return
            end
            
            for i = 1:length(s)
                obj = subsref(obj,s(i));
            end
        end
        
        %{
            signal manipulation
        %}
        
        %   - windowing
        
        function obj = window(obj,step,w_size)
            obj = window_obj(obj,step,w_size);
        end
        
        %   - downsampling
      
        function obj = downsample(obj,new_fs)
            obj = downsample_obj(obj,new_fs);
        end
            
    end
    
end