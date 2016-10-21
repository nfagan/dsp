classdef dsp__Plotter
    
    properties ( Constant = true )
        errors = struct(...
            'errNotObject', 'The input must be a DataObject' ...
        );
    end
    
    methods ( Static )
        
        %{
            scaling
        %}
        
        function clims = autoscaler(obj, type)
            if ( nargin < 2 ); type = 'relaxed'; end
            
            dsp__Plotter.assert__obj(obj);
            
            %{
                scale either 'relaxed', such that some data might be
                clipped, or 'strict', such that all data will be within
                <clims>
            %}
            
            switch type
                case 'relaxed'
                    global_min = min( obj.cellfun(@(x) mean(mean(x)) - 2.5*mean(std(x))) );
                    global_max = max( obj.cellfun(@(x) mean(mean(x)) + 2.5*mean(std(x))) );
                case 'strict'
                    global_min = min( obj.cellfun(@(x) min(min(x))) );
                    global_max = max( obj.cellfun(@(x) max(max(x))) );
            end

            clims = [global_min global_max];
        end
        
        %{
            string handling: title strings, filenames, etc.
        %}
        
        function id = create_identifier(obj)
            dsp__Plotter.assert__obj(obj);
            
            if ( count(obj,1) > 1 )
                fprintf(['\nWARNING: Only one object''s labels will be used' ...
                    , ' to create an id for multiple objects']);
                obj = obj(1);
            end
            
            fields = obj.label_fields;

            for i = 1:numel(fields)
                labels = char( unique(obj(fields{i})) );

                if ( i == 1 ); id = labels; continue; end;

                id = sprintf('%s_%s', id, labels);
            end            
        end
        
        function str = titleify(str)
            underscores = strfind(str,'_');
            str(underscores) = ' ';
        end
        
        %   generic x and y axis label generator
        
        function labels = axislabeler(vector, varargin)
            assert( any(size(vector) == 1), 'First input must be a vector' );
            
            params = struct(...
                'step', 5, ...
                'retainLast', true, ...
                'retainZero', true ...
            );            
            params = parsestruct(params, varargin);
            
            labels = repmat( {''}, 1, numel(vector) );

            for k = 1:params.step:numel(labels)
                labels{k} = num2str( vector(k) );
            end
            
            if ( params.retainLast ); labels{end} = num2str( vector(end) ); end;            
            
            if ( params.retainZero )
                zero_index = vector == 0;
                if ( ~any(zero_index) || any(strcmp(labels, '0')) ); return; end;
                labels{zero_index} = '0';
            end
        end
        
        %   time (x) label generator
        
        function labels = timelabels(time, varargin)
            params = struct( 'step', 10, 'retainLast', false );
            params = struct2varargin( parsestruct(params, varargin) );
            labels = dsp__Plotter.axislabeler( time, params{:} );
        end
        
        %   frequency (y) label generator
        
        function labels = freqlabels(freqs, varargin)
            params = struct( 'step', 10, 'retainLast', false ); 
            params = struct2varargin( parsestruct(params, varargin) );
            labels = dsp__Plotter.axislabeler( freqs, params{:} );
        end
        
        %{
            validation
        %}
        
        function assert__obj(varargin)
            for k = 1:numel(varargin)
                assert( isa(varargin{k}, 'DataObject'), dsp__Plotter.errors.errNotObject );
            end            
        end       
        
    end
    
end