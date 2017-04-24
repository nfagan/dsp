classdef SignalStruct
    
    properties
        signals = struct();
    end
    
    methods
        
        function obj = SignalStruct(structure)            
            SignalStruct.validate_structure(structure);
            
            fields = fieldnames(structure);
            for i = 1:numel(fields)
               signals.(fields{i}) = structure.(fields{i});
            end
           
            obj.signals = signals;
        end
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;

            switch type
                case '.'
                    
                    %   return the property <subs> if subs is a property
                    
                    if any(strcmp(properties(obj), subs))
                        out = obj.(subs); return;
                    end
                    
                    %   call the function on the obj is <subs> is a
                    %   SignalStruct method
                    
                    if any( strcmp(methods(obj), subs) )
                        func = eval(sprintf('@%s',subs));
                        inputs = [{obj} {s(:).subs{:}}];
                        out = func(inputs{:}); return;
                    end                    
                    
                    fields = signalfields(obj);
                    signal_obj_funcs = methods(obj.signals.(fields{1}));
                    
                    %   call the function on each signal field if <subs> is
                    %   a method
                    
                    if any(strcmp(signal_obj_funcs,subs))
                        out = obj;
                        func = eval(sprintf('@%s',subs));
                        inputs = {s(:).subs{:}};
                        out.signals = structfun(@(x) func(x, inputs{:}),...
                            obj.signals, 'UniformOutput', false);
                        return;
                    end
                    
                    %   return the signals if <subs> is a signal field
                    
                    if any(strcmp(fields, subs))
                        out = obj.signals.(subs);
                    end
                    
                    %   return a property of the first signal object
                    %   if <subs> is a SignalObject property
                    
                    obj_props = properties(obj.signals.(fields{1}));
                    
                    if any(strcmp(obj_props, subs))
                        out = obj.signals.(fields{1}).(subs);
                    end
                otherwise
                    error('Unsupported reference method');
            end

            if isempty(s)
                return;
            end

            out = subsref(out,s);
        end
        
        function obj = renamefield(obj, from, to)
            assert( issignalfield(obj, from), ...
                'The field ''%s'' is not in the object' );
            current = obj.signals.(from);
            new = rmfield(obj.signals, from);
            new.(to) = current;
            obj.signals = new;
        end
        
        function fields = signalfields(obj)
            fields = fieldnames(obj.signals);
        end
        
        function tf = issignalfield(obj, field)
            fields = signalfields(obj);
            tf = any( strcmp(fields, field) );
        end
        
        function disp(obj)
            disp(obj.signals);
        end
    end
    
    methods (Static)
        
        function validate_structure(structure)
            structfun(@(x) assert(isa(x, 'SignalObject')), structure);
            
%             fields = fieldnames(structure);
%             for i = 1:numel(fields)
%                 if ( i == 1 ); to_compare = structure.(fields{i}); continue; end;
%                 assert( labeleq(to_compare, structure.(fields{i})), ...
%                     'Labels must be equal between objects' );
%                 to_compare = structure.(fields{i});
%             end
        end
        
    end
    
end