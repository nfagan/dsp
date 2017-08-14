classdef SignalContainer < Container
  
  properties
    fs = NaN;
    start = NaN;
    stop = NaN;
    window_size = NaN;
    step_size = NaN;
    trial_ids = [];
    trial_stats = struct( ...
      'range', [] ...
    );
    params = struct( ...
        'coherenceType', 'chronux' ...
      , 'powerType', 'chronux' ...
      , 'referenceType', 'common_averaged' ...
      , 'subtractBinMean', true ...
      , 'trialByTrialMean', false ...
      , 'chronux_params', struct('tapers', [1.5 2]) ...
      , 'normMethod', 'divide' ...
      , 'removeNormPowerErrors', true ...
    );
    frequencies = NaN;
  end
  
  methods
    function obj = SignalContainer( data, labels, fs, start_stop, window, trial_ids, freqs )
      obj = obj@Container( data, labels );
      if ( nargin == 2 )
        obj.trial_ids = (1:size(data, 1))';
        stat_fields = fieldnames( obj.trial_stats );
        for k = 1:numel(stat_fields)
          obj.trial_stats.(stat_fields{k}) = obj.trial_ids;
        end
        return; 
      end;
      if ( nargin == 7 ), obj.frequencies = freqs; end;
      obj.fs = fs;
      obj.start = start_stop(1);
      obj.stop = start_stop(2);
      obj.step_size = window(1);
      obj.window_size = window(2);
      assert( numel(trial_ids) == shape(obj, 1), ['The number of trial_ids' ...
        , ' must match the number of rows in the object'] );
      obj.trial_ids = trial_ids(:);
      %   obtain the range of values, per trial.
      obj = update_range( obj );
    end
    
    %{
        INDEXING
    %}
    
    function obj = reorder_data(obj, ind)
      
      %   REORDER_DATA -- Reorder the data in the object (including
      %     trial_stats and trial_ids) according to a numeric index.
      %
      %     Labels are not reordered.
      %
      %     IN:
      %       - `ind` (double) -- Numeric index whose values are entirely
      %         unique; must be a vector with the same number of elements
      %         as the SignalContainer has rows.
      
      assert( isa(ind, 'double'), ['Expected the index to be a numeric index;' ...
        , ' was a ''%s''.'], class(ind) );
      assert( numel(unique(ind)) == numel(ind), ['There cannot be duplicate' ...
        , ' values in the index.'] );
      msg = ['The index must be a vector with the same number of elements' ...
        , ' as the object has rows.'];
      assert( isvector(ind), msg );
      assert( numel(ind) == shape(obj, 1), msg );
      
      colons = repmat( {':'}, 1, ndims(obj.data-1) );
      obj.data = obj.data( ind, colons{:} );
      obj.trial_ids = obj.trial_ids( ind );
      obj.trial_stats = structfun( @(x) x(ind), obj.trial_stats, 'un', false );      
    end
    
    function obj = keep(obj, ind)
      
      %   KEEP -- Retain elements at the specified index.
      %
      %     See `help Container/keep` for more information
      %
      %     IN:
      %       - `ind` (logical) |COLUMN| -- Elements to retain.
      
      obj = keep@Container( obj, ind );
      obj.trial_ids = obj.trial_ids( ind );
      obj = keep_trial_stats( obj, ind );
    end
    
    function [obj, ind] = remove(obj, selectors)
      
      %   REMOVE -- Remove elements identified by the labels in selectors.
      %
      %     See `help Container/remove` for more information.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- Labels to
      %         identify rows to remove.
      %     OUT:
      %       - `ind` (logical) -- Index of the removed elements with
      %         respect to the original object.      
      
      [obj, ind] = remove@Container( obj, selectors );
      obj.trial_ids = obj.trial_ids( ~ind );
      obj = keep_trial_stats( obj, ~ind );
    end
    
    function [obj, ind] = remove_nans_and_infs(obj)
      
      %   REMOVE_NANS_AND_INFS -- Remove rows of data containg NaN or Inf
      %     values.
      %
      %     Note that, if even one value in a row is Inf or NaN, the whole
      %     row is removed.
      
      if ( ndims(obj.data) == 3 )
        ind = any( any(isinf(obj.data) | isnan(obj.data), 3), 2 );
      else
        ind = any( isinf(obj.data) | isnan(obj.data), 2 );
      end
      obj = keep( obj, ~ind );
    end
    
    function obj = only_not(obj, selectors)
      
      %   ONLY_NOT -- Retain elements not in *all* labels in
      %     selectors.
      %
      %     In contrast to `remove()`, only rows that match all labels in
      %     `selectors` will be removed.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- Labels to
      %         identify rows to remove.
      
      ind = where( obj, selectors );
      obj = keep( obj, ~ind );
    end
    
    function obj = keep_trial_stats(obj, ind)
      
      %   KEEP_TRIAL_STATS -- Index each field of `obj.trial_stats` with
      %     respect to the given index.
      %
      %     Used internally to simplify the keep() function; see `help
      %     Container/keep` for more information.
      
      obj.trial_stats = structfun( @(x) x(ind), obj.trial_stats, 'un', false );
      assert__properly_dimensioned_trial_stats( obj, obj.trial_stats );
    end
    
    function obj = retain_by_id(obj, ids)
      
      %   RETAIN_BY_ID -- Only retain trials that match the given ids.
      %
      %     IN:
      %       - `ids` (double) -- Vector of in-bounds ids.
      
      ids = unique( ids );
      matches = arrayfun( @(x) any(ids == x), obj.trial_ids );
      obj = keep( obj, matches );
    end
    
    function obj = keep_within_range(obj, threshold)
      
      %   KEEP_WITHIN_RANGE -- Only keep trials where the range is less
      %     than or equal to a given value.
      %
      %     IN:
      %       - `threshold` (double) |SCALAR|
      
      assert__properly_dimensioned_trial_stats( obj, obj.trial_stats );
      ind = obj.trial_stats.range <= threshold;
      obj = keep( obj, ind );
    end
    
    function obj = keep_within_times(obj, time_)
      
      %   KEEP_WITHIN_TIMES -- Only retain data associated with the
      %     specified times.
      %
      %     Data in the object must be a three-dimensional
      %     trials-by-frequencies-by-times array, i.e., the result of an
      %     analysis function.
      %
      %     IN:
      %       - `time_` (double) -- Two-element double specifying the start
      %         and stop time. An error is thrown if the times are out of
      %         bounds.
      
      time_series = get_time_series( obj );
      assert( numel(time_) == 2, ['Expected desired times to be a' ...
        , ' two-element double, but there were %d elements.'], numel(time_) );
      assert( time_(1) <= time_(2), ['The first time-point must be earlier' ...
        , ' than or the same as the second.'] );
      assert( ndims(obj.data) == 3, 'Data in the object must be three-dimensional.' );
      assert( numel(time_series) == size(obj.data, 3), ['The time properties' ...
        , ' in the object do not properly correspond to the size of the data' ...
        , ' in the third dimension.'] );
      ind1 = find( time_series >= time_(1), 1, 'first' );
      ind2 = find( time_series <= time_(2), 1, 'last' );
      assert( ~isempty(ind1) && ~isempty(ind2), ['Could not find the start' ...
        , ' or end time.'] );
      obj.data = obj.data( :, :, ind1:ind2 );
      obj.start = time_series( ind1 );
      obj.stop = time_series( ind2 );
    end
    
    function obj = keep_within_freqs(obj, freqs)
      
      %   KEEP_WITHIN_FREQS -- Only retain data associated with the
      %     specified frequencies.
      %
      %     Data in the object can be two- or three-dimensional, but the
      %     number of columns in the object must correspond to the
      %     `frequencies` property.
      %
      %     IN:
      %       - `freqs` (double) -- Two-element double specifying the start
      %         and stop frequencies. An error is thrown if the frequencies
      %         are out of bounds.
      
      frequencies = obj.frequencies;
      assert( numel(freqs) == 2, ['Expected desired frequencies to be a' ...
        , ' two-element double, but there were %d elements.'], numel(freqs) );
      assert( freqs(1) < freqs(2), ['The first frequency must be less' ...
        , ' than the second.'] );
      assert( numel(frequencies) == size(obj.data, 2), ['The frequencies' ...
        , ' in the object do not properly correspond to the size of the data' ...
        , ' in the second dimension.'] );
      ind1 = find( frequencies >= freqs(1), 1, 'first' );
      ind2 = find( frequencies <= freqs(2), 1, 'last' );
      assert( ~isempty(ind1) && ~isempty(ind2), ['Could not find the start' ...
        , ' or end frequency.'] );
      if ( ndims(obj.data) == 3 )
        obj.data = obj.data( :, ind1:ind2, : );
      else obj.data = obj.data( :, ind1:ind2 );
      end
      obj.frequencies = obj.frequencies( ind1:ind2 );
    end
    
    %{
        SIGNAL PROCESSING
    %}
    
    function obj = filter(obj, varargin)
      
      %   FILTER -- Apply filtering to the raw signals in `obj.data`.
      
      obj = SignalObject__filter( obj, varargin{:} );
    end
    
    function obj = rmline(obj, F, chron_params)
      
      %   RMLINE -- Remove line noise from the raw signals in `obj.data`.
      %
      %     IN:
      %       - `F` (double) |OPTIONAL| -- Frequency to target for noise
      %         removal. Defaults to 60.
      %       - `chron_params` (struct) |OPTIONAL| -- Struct with 'Fs',
      %         'fpass', and 'tapers' fields. Defaults to a struct where
      %         'Fs' is the obj.fs property, 'fpass' is [50, 70], and
      %         'tapers' is [3, 5].
      
      if ( nargin < 2 ), F = 60; end
      if ( nargin < 3 )
        chron_params = struct( 'Fs', obj.fs, 'fpass', [], 'tapers', [2, 3] );
      end
      assert( ismatrix(obj.data), ['Data in the object must be an MxN' ...
        , ' matrix of M trials and N samples.'] );
      signals = obj.data';
%       signals = rmlinesc( signals, chron_params, [], [], F );
      wo = F / (obj.fs/2);
      [b, a] = iirnotch( wo, wo/50, -.005 );
      signals = filter( b, a, signals );
      obj.data = signals';
    end
    
    function obj = downsample(obj, new_fs)
      
      %   DOWNSAMPLE -- Downsample data to a new target sampling rate.
      %
      %     The new sampling rate must be an integer factor of the current
      %     sampling rate, and smaller than the original sampling rate.
      %
      %     IN:
      %       - `new_fs` (double)
      
      assert( ismatrix(obj.data), ['Data in the object must be an MxN' ...
        , ' matrix of M trials by N time samples.'] );
      factor = obj.fs / new_fs;
      assert( factor > 1 && round(factor) == factor, ['The new sampling rate' ...
        , ' (%0.2f) is not an integer factor of the original sampling rate (%0.2f)'] ...
        , new_fs, obj.fs );
      newdata = [];
      for i = 1:size( obj.data, 1 )
        newdata(i, :) = downsample( obj.data(i, :), factor );
      end
      obj.data = newdata;
      obj.fs = new_fs;
    end
    
    %{
        DATA PROCESSING
    %}
    
    function data = windowed_data(obj)
      
      %   WINDOWED_DATA -- Bin signals into a cell array with as many
      %     elements as (window_size/step_size).
      %
      %     OUT:
      %       - data (cell array) -- Binned signal array of dimensions
      %         1x(window_size/step_size)
      
      data = ...
        SignalObject__get_windowed_data( obj, obj.step_size, obj.window_size );
    end
    
    function new_obj = create_trial_sets(obj, categories)
      
      %   CREATE_TRIAL_SETS -- Create an array of trial-sets where each set
      %     is composed of trials drawn from the unique combinations of
      %     labels in the desired categories.
      %
      %     IN:
      %       - `categories` (cell array of strings, char) -- Categories
      %       from which to draw unique sets of labels. An error is thrown
      %       if any of the specified categories do not exist.
      
      c = combs( obj.labels, categories );
      new_obj = Container();
      for i = 1:size(c, 1)
        current = create_trial_set( obj, c(i, :) );
        if ( isempty(current) ), continue; end;
        new_obj = append( new_obj, current );
      end
    end
    
    function obj = create_trial_set(obj, selectors)
      
      %   CREATE_TRIAL_SET -- Reformat an analysis-output to create an
      %     object whose data are a 1xM cell array.
      %
      %     M is the number of time-bins in the object; each matrix in the 
      %     cell array is a NxQ array of analyses-values, where N is the
      %     number of frequencies in obj.frequencies, and Q the number of
      %     trials associated with the given selectors.
      %
      %     An error is thrown if the object is not the result of an
      %     analysis output; i.e., if the dtype of the object is not
      %     'cell'.
      %
      %     IN:
      %       - `selectors` (cell array of strings, char) -- Labels to
      %         identify trials to form a trial-set.
      
      [ind, fields] = where( obj, selectors );
      obj = keep( obj, ind );
      if ( isempty(obj) ), return; end;
      assert( isequal(obj.dtype, 'cell'), ['Cannot create a trial-set' ...
        , ' from data of class ''%s'''], obj.dtype );
      trials = obj.data;
      reformatted = cell( 1, size(trials, 2) );
      for i = 1:numel(reformatted)
        reformatted{i} = cell2mat( trials(:, i) )';
      end
      obj = subsref( obj, struct('type', '()', 'subs', {{1}}) );
      obj.data = reformatted;
      if ( isa(obj.labels, 'SparseLabels') )
        cats = unique( obj.labels.categories );
      else cats = obj.labels.fields;
      end
      to_collapse = setdiff( cats, unique(fields) );
      obj = collapse( obj, to_collapse );
    end
    
    %{
        AVERAGING
    %}
    
    function obj = mean_across(obj, across)
      
      %   MEAN_ACROSS -- Average the data in the object across the
      %     specified catgory or categories.
      %
      %     IN:
      %       - `across` (cell array of strings, char) -- Categories to
      %         average across.
      
      obj = collapse( obj, across );
      obj = mean_within( obj, obj.field_names() );
    end
    
    function new_obj = mean_within(obj, within)
      
      %   MEAN_WITHIN -- Average the data in the object to the given
      %     specifity.
      %
      %     Data must be an MxNxP double array of M trials, N frequencies,
      %     and P time bins.
      %
      %     IN:
      %       - `within` (cell array of strings, char) -- Means will be
      %         taken within the unique combinations of labels present in
      %         these categories.
      
      c = combs( obj, within );
      new_obj = Container();
      for i = 1:size(c, 1)
        extr = only( obj, c(i, :) );
        if ( isempty(extr) ), continue; end;
        data = nanmean( extr.data, 1 );
        trial_stats = structfun( @(x) nanmean(x, 1), extr.trial_stats, 'un', false );
        extr = subsref( extr, struct('type', '()', 'subs', {{1}}) );
        extr.data = data;
        extr.trial_stats = trial_stats;
        if ( isa(extr.labels, 'SparseLabels') )
          cats = unique( obj.labels.categories );
        else cats = obj.labels.fields;
        end
        to_collapse = setdiff( cats, unique(within) );
        extr = collapse( extr, to_collapse );
        new_obj = append( new_obj, extr );
      end   
    end
    
    function obj = trial_mean(obj)
      
      %   TRIAL_MEAN -- Take a mean over all trials in the object (across
      %     the first dimension).
      %
      %     All categories in the labels object are collapsed.
      
      if ( isa(obj.labels, 'SparseLabels') )
        cats = unique( obj.labels.categories );
      else cats = obj.labels.fields;
      end      
      obj = collapse( obj, cats );
      data = mean( obj.data, 1 );
      obj = subsref( obj, struct('type', '()', 'subs', {{1}}) );
      obj.data = data;      
    end
    
    function obj = time_mean(obj, time)
      
      %   TIME_MEAN -- Take a mean of the data over the specified
      %     time-interval, within trials and frequencies.
      %
      %     Data must be the result of an analysis output; i.e., be an
      %     MxNxP matrix of M trials, N frequencies, and P time-bins.
      %
      %     IN:
      %       - `time` (double) -- Two element vector specifying the start
      %         and stop of the range over which to take a mean. Must be
      %         within obj.start and obj.stop.
      
      assert( ndims(obj.data) == 3, ['Data in the object must an MxNxP' ...
        , ' matrix of M trials, N frequencies, and P time-bins'] );
      time_vec = obj.start:obj.step_size:obj.stop;
      SignalContainer.assert__dimensions_match( time_vec, size(obj.data, 3), 'times' );
      SignalContainer.assert__within_bounds( time, time_vec, 'times' );
      time_inds = time_vec >= time(1) & time_vec <= time(2);
      obj.data = mean( obj.data(:, :, time_inds), 3 );
    end
    
    function obj = freq_mean(obj, freqs)
      
      %   FREQ_MEAN -- Take a mean of the data over the specified
      %     frequency-interval, within trials and time-bins. If there are
      %     no time-bins, 
      %
      %     Data must be the result of an analysis output, and can be
      %     either an MxNxP matrix of M trials, N frequencies, and P
      %     time-bins, or an MxN matrix of M trials and N frequencies.
      %
      %     IN:
      %       - `freqs` (double) -- Two element vector specifying the start
      %         and stop of the range over which to take a mean. Must be
      %         within obj.frequencies.
      
      freq_vec = obj.frequencies;
      SignalContainer.assert__dimensions_match( freq_vec, size(obj.data, 2) ...
        , 'frequencies' );
      SignalContainer.assert__within_bounds( freqs, freq_vec, 'frequencies' );
      freq_inds = freq_vec >= freqs(1) & freq_vec <= freqs(2);
      if ( ndims(obj.data) == 2 ) %#ok
        obj.data = mean( obj.data(:, freq_inds), 2 );
      else obj.data = mean( obj.data(:, freq_inds, :), 2 );
      end
    end
    
    function obj = time_freq_mean(obj, time, freq)
      
      %   TIME_FREQ_MEAN -- Get a mean value over the specified time and
      %     frequencies.
      %
      %     Specify time or freq as [] to take a mean over all times or
      %     all frequencies. See `help SignalContainer/time_mean` and `help
      %     SignalContainer/freq_mean` for input restrictions and necessary
      %     dimensions.
      %
      %     IN:
      %       - `time` (double, []) -- Two element vector specifying the
      %         start and stop of the time-range over which to take a mean,
      %         or []. If [], the average is over all time-bins.
      %       - `freq` (double, []) -- Two element vector specifying the
      %         start and stop of the frequency-range over which to take a
      %         mean, or []. If [], the average is over all frequencies.
      
      if ( isempty(time) ), time = [obj.start, obj.stop]; end;
      if ( isempty(freq) ), freq = [obj.frequencies(1), obj.frequencies(2)]; end;
      
      obj = time_mean( obj, time );
      obj = freq_mean( obj, freq );
    end
    
    function obj_ = row_op(obj, varargin)
      
      %   ROW_OP -- Overloaded row-operations method which acts on the
      %     fields of `trial_stats` in addition to the data in the object.
      %
      %     See `help Container/row_op` for more information.
      
      obj_ = row_op@Container( obj, varargin{:} );
      func = varargin{1};
      varargin(1) = [];
      trial_stats = obj.trial_stats;
      trial_stats = structfun( @(x) func(x, varargin{:}), trial_stats ...
        , 'un', false );
      obj_.trial_stats = trial_stats;
    end
    
    %{
        ANALYSIS
    %}
    
    function [coh, f] = coherence(obj, B, varargin)
      
      %   COHERENCE -- Obtain trial-wise coherence estimates for the data
      %     in two SignalContainers.
      %
      %     Both objects must be 'double' type objects.
      %
      %     IN:
      %       - `B` (SignalContainer) -- Second trial-set. Must have the
      %         same number of rows as the first object.
      %       - `varargin` (/any/) -- Various additional parameters. See
      %         obj.params.
      %     OUT:
      %       - `coh` (cell array) -- Array of M frequencies x N trial
      %         coherence values
      %       - `f` (double) -- Vector of frequencies.
      
      assert__capable_of_coherence( obj, B );
      params = obj.params;  %#ok<*PROPLC>
      params = parsestruct( params, varargin );
      A = windowed_data( obj );
      B = windowed_data( B );
      coh = cell( 1, numel(A) );
      for i = 1:numel(A)
        a = A{i}';
        b = B{i}';        
        switch ( params.coherenceType )
          case 'chronux'
            params.chronux_params.Fs = obj.fs;
            [C,~,~,~,~,f] = coherencyc(a, b, params.chronux_params );
          otherwise
            assert( ~any(isnan(obj.frequencies)), 'Frequencies have not been set' );
            [C, f] = mscohere( a, b, [], [], obj.frequencies, obj.fs );
        end
        if ( size(C, 1) == 1 ), C = C'; end;
        if ( size(f,1) < size(f,2) ), f = f'; end;        
        coh{i} = C;
     end
    end
    
    function [coh, f] = sfcoherence(obj, B, varargin)
      
      %   SFCOHERENCE -- Obtain trial-wise spike-field coherence estimates.
      %
      %     [coh, f] = sfcoherence(A, B) calculates the coherence between
      %     spiking data in A and continuous data in B.
      %
      %     IN:
      %       - `B` (SignalContainer) -- Second trial-set. Must have the
      %         same number of rows as the first object.
      %       - `varargin` (/any/) -- Various additional parameters. See
      %         obj.params.
      %     OUT:
      %       - `coh` (cell array) -- Array of M frequencies x N trial
      %         coherence values
      %       - `f` (double) -- Vector of frequencies.
      
      assert__capable_of_sfcoherence( obj, B );
      params = obj.params;  %#ok<*PROPLC>
      params = parsestruct( params, varargin );
      A = windowed_data( obj );
      B = windowed_data( B );
      coh = cell( 1, numel(A) );
      for i = 1:numel(A)
        a = dsp2.process.format.to_struct_times( A{i}, obj.fs );
        b = B{i}';
        switch ( params.coherenceType )
          case 'chronux'
            params.chronux_params.Fs = obj.fs;
            [C,~,~,~,~,f] = coherencycpt( b, a, params.chronux_params );
          otherwise
            error( ['No spike-field coherence procedure has been defined for' ...
              , ' ''%s''.'], params.coherenceType );
        end
        if ( size(C, 1) == 1 ), C = C'; end;
        if ( size(f,1) < size(f,2) ), f = f'; end;        
        coh{i} = C;
     end
    end
    
    function [pow, w] = raw_power(obj, varargin)
      
      %   RAW_POWER -- Obtain trial-wise spectral-power estimates for the
      %     data in a SignalContainer.
      %
      %     The object must have data that are a double matrix; i.e., it
      %     must have dtype = 'double';
      %
      %     IN:
      %       - `varargin` (/any/) -- Various additional parameters. See
      %         obj.params.
      %     OUT:
      %       - `pow` (cell array) -- Array of M frequencies x N trial
      %         power values
      %       - `f` (double) -- Vector of frequencies.
      
      assert( isequal(obj.dtype, 'double'), ['Signals must be stored in' ...
        , ' a regular double matrix; were of class ''%s'''], obj.dtype );
      
      A = windowed_data( obj );
      pow = cell( 1, numel(A) );
      params = obj.params;
      for i = 1:numel(A)   
        a = A{i}';
        if ( params.subtractBinMean )
          mean_within_bin = mean( a );
          for k = 1:size( a, 1 )
            a(k, :) = a(k, :) - mean_within_bin;
          end
        end
        switch ( params.powerType )
          case 'chronux'
            params.chronux_params.Fs = obj.fs;
            [pxx, w] = mtspectrumc( a, params.chronux_params );
          case 'periodogram'
            [pxx, w] = periodgram( a, [], obj.frequencies, obj.fs );
          case 'multitaper'
            [pxx, w] = pmtm( a, nw, obj.frequencies, obj.fs );
        end
        pow{i} = pxx;
      end
      if ( any(size(w) == 1) ), w = w(:); end;
    end
    
    function [pow, w] = norm_power(obj, B, varargin)
      
      %   NORM_POWER -- Calculate normalized power by subtracting or
      %     dividing the power-values in one object from those in another
      %     object.
      %
      %     IN:
      %       - `obj` (SignalContainer) -- Object to-be-normalized.
      %       - `B` (SignalContainer) -- Normalizing-object. Must have only
      %         one time window's worth of data. Must have the same number
      %         of rows as `obj`.
      %       - `varargin` (/any/) -- Various additional parameters to
      %         overwrite those in obj.params
      %     OUT:
      %       - `pow` (cell array) -- Array of M frequencies x N trial
      %         power values
      %       - `w` (double) -- Vector of frequencies.
      
      assert__capable_of_norm_power( obj, B );
      [own, w] = raw_power( obj, varargin{:} );
      other = raw_power( B, varargin{:} );
      other = other{1};
      if ( ~obj.params.trialByTrialMean )
        n_cols = size( other, 2 );
        if ( obj.params.removeNormPowerErrors )
          errors = all( other == 0, 1 );
          other = other( :, ~errors );
        end
        other = mean( other, 2 );
        other = repmat( other, 1, n_cols );
      end
      switch ( obj.params.normMethod )
        case 'subtract'
          pow = cellfun( @(x) x-other, own, 'un', false );
        case 'divide'
          pow = cellfun( @(x) x./other, own, 'un', false );
      end
    end
    
    %{
        RUN ANALYSES
    %}
    
    function obj = run_raw_power(obj, varargin)
      
      %   RUN_RAW_POWER -- Convert the signal data in the object to time x
      %     frequency data.
      %
      %     IN:
      %       - `obj` (SignalContainer) -- Object whose data are an MxN
      %         matrix of M trials by N voltage samples.
      %       - `varargin` (/any/) -- Any additional inputs to be passed to
      %         the raw_power() method.
      %     OUT:
      %       - `obj` (SignalContainer) -- Object whose data are an MxNxP
      %         matrix of M trials, N frequencies, and P time-bins.
      
      [pow, f] = raw_power( obj, varargin{:} );
      pow = SignalContainer.get_trial_by_time_double( pow );
      obj.data = pow;
      obj = update_frequencies( obj, f(:, 1) );
    end
    
    function obj = run_normalized_power(obj, obj2, varargin)
      
      %   RUN_NORMALIZED_POWER -- Normalize the power of the data in `obj`
      %     by the power of the data in `obj2`.
      %
      %     IN:
      %       - `obj` (SignalContainer) -- SignalContainer object whose
      %         data are an MxN matrix of M trials by N voltage samples.
      %         The to-be-normalized data.
      %       - `obj2` (SignalContainer) -- SignalContainer object whose
      %         data are an MxN matrix of M trials by N voltage samples.
      %         The normalizing data.
      %     OUT:
      %       - `to_norm` (SignalContainer) -- Normalized object.
      
      [pow, f] = norm_power( obj, obj2, varargin{:} );
      mins = min( [obj.trial_stats.min, obj2.trial_stats.min], [], 2 );
      maxs = max( [obj.trial_stats.max, obj2.trial_stats.max], [], 2 );
      %   get actual normalized power
      pow = SignalContainer.get_trial_by_time_double( pow );
      obj.data = pow;
      obj = update_frequencies( obj, f(:, 1) );
      obj.trial_stats.range = ...
        max( [obj.trial_stats.range, obj2.trial_stats.range], [], 2 );
      obj.trial_stats.min = mins;
      obj.trial_stats.max = maxs;
    end
    
    function store = run_coherence(obj, varargin)
      
      %   RUN_COHERENCE -- Calculate coherence between BLA and ACC,
      %     per-day / session.
      %
      %     IN:
      %       - `varargin` (/any/) -- Additional ('name', value) pair
      %       	arguments to be passed to coherece( obj )
      %     OUT:
      %       - `store` (SignalContainer) -- SignalContainer object whose
      %         regions field is 'bla', and whose data are an MxNxP matrix
      %         of M trials, N frequencies, and P time bins.
      
      reg1_ind = strcmp( varargin, 'reg1' );
      reg2_ind = strcmp( varargin, 'reg2' );
      cmb_ind = strcmp( varargin, 'combs' );
      to_rm = false( size(varargin) );
      err_msg = 'Expected the %s to follow the %s selector.';
      manual_combs = false;
      if ( any(reg1_ind) )
        reg1_ind = find( reg1_ind );
        assert( reg1_ind+1 <= numel(varargin), err_msg, 'region', 'reg' );
        reg1 = varargin{ reg1_ind+1 };
        to_rm( reg1_ind:reg1_ind+1 ) = true;
      else
        reg1 = 'bla';
      end
      if ( any(reg2_ind) )
        reg2_ind = find( reg2_ind );
        assert( reg2_ind+1 <= numel(varargin), err_msg, 'region', 'reg' );
        reg2 = varargin{ reg2_ind+1 };
        to_rm( reg2_ind:reg2_ind+1 ) = true;
      else
        reg2 = 'acc';
      end
      if ( any(cmb_ind) )
        cmb_ind = find( cmb_ind );
        assert( cmb_ind+1 <= numel(varargin), err_msg );
        cmbs = varargin{ cmb_ind+1 };
        assert( iscellstr(cmbs), 'Combinations must be a cell array of strings.' );
        to_rm( cmb_ind:cmb_ind+1 ) = true;
        manual_combs = true;
      end
      varargin( to_rm ) = [];
      assert( ndims(obj.data) == 2, ['Expected the data to be a 2-d trials' ...
        , ' x samples matrix.'] );
      days = flat_uniques( obj.labels, 'days' );
      store = Container();
      for i = 1:numel(days)
        fprintf( '\n - Processing day %d of %d', i, numel(days) );
        bla = only( obj, {reg1, days{i}} );
        acc = only( obj, {reg2, days{i}} );  
        bla_channels = flat_uniques( bla.labels, 'channels' );
        acc_channels = flat_uniques( acc.labels, 'channels' );
        if ( ~manual_combs )
          product = allcomb( {bla_channels, acc_channels} );
        else
          product = cmbs;
        end
        for k = 1:size( product, 1 )
          fprintf( '\n\t - Processing channel combination %d of %d' ...
            , k, size(product, 1) );
          one_bla = only( bla, product{k, 1} );
          one_acc = only( acc, product{k, 2} );
          assert( shape(one_bla, 1) == shape(one_acc, 1), 'Sizes do not match' );
          [coh, freqs] = coherence( one_bla, one_acc, varargin{:} );
          arr = SignalContainer.get_trial_by_time_double( coh );
          mins = min( [one_bla.trial_stats.min, one_acc.trial_stats.min], [], 2 );
          maxs = max( [one_bla.trial_stats.max, one_acc.trial_stats.max], [], 2 );
          one_bla.data = arr;
          one_bla.trial_stats.min = mins;
          one_bla.trial_stats.max = maxs;
          site_str = [ 'site__' num2str(k) ];
          if ( ~one_bla.labels.contains_fields('sites') )
            one_bla = one_bla.add_field( 'sites', site_str );
          else
            one_bla.labels = one_bla.labels.set_field( 'sites', site_str );
          end
          bla_range = one_bla.trial_stats.range;
          acc_range = one_acc.trial_stats.range;
          one_bla.trial_stats.range = max( [bla_range, acc_range], [], 2 );
          store = append( store, one_bla );
        end
      end
      store = update_frequencies( store, freqs(:, 1) );
      reg_names = strjoin( {reg1, reg2}, '_' );
      store.labels = store.labels.set_field( 'regions', reg_names );
    end
    
    function store = run_sfcoherence(obj, signals, varargin)
      
      %   RUN_SFCOHERENCE -- Calculate spike-field coherence between
      %     regions.
      %
      %     IN:
      %       - `varargin` (/any/) -- Additional ('name', value) pair
      %       	arguments to be passed to sfcoherece( obj )
      %     OUT:
      %       - `store` (SignalContainer) -- SignalContainer object whose
      %         regions field is 'bla', and whose data are an MxNxP matrix
      %         of M trials, N frequencies, and P time bins.
      
      spike_regions = flat_uniques( obj.labels, 'regions' );
      signal_regions = flat_uniques( signals.labels, 'regions' );
      assert( numel(spike_regions) == 1 && numel(signal_regions) == 1 ...
        , 'More than one region was present in the spiking or continuous data.' );
      reg_names = strjoin( {spike_regions{1}, signal_regions{1}}, '_' );
      store = Container();
      days = flat_uniques( obj.labels, 'days' );
      for k = 1:numel(days)
        extr_spikes = only( obj, days{k} );
        extr_signals = only( signals, days{k} );
        one_day = per_day( extr_spikes, extr_signals, varargin{:} );
        store = append( store, one_day );
      end
      store.labels = store.labels.set_field( 'regions', reg_names );
      store.dtype = class( store.data );
      
      function store = per_day(spikes, signals, varargin)
        spike_chans = flat_uniques( spikes.labels, 'channels' );
        signal_chans = flat_uniques( signals.labels, 'channels' );
        all_chans = allcomb( {spike_chans, signal_chans} );
        store = cell(1, size(all_chans, 1) );
        freqs = cell( size(store) );
        parfor i = 1:size(all_chans, 1)
          spike_chan = all_chans{i, 1};
          signal_chan = all_chans{i, 2};
          spike = only( spikes, spike_chan );
          signal = only( signals, signal_chan );
          assert( shape(spike, 1) == shape(signal, 1), ['Shapes of' ...
            , ' spikes and continuous data must match.'] );
          [coh, freqs{i}] = sfcoherence( spike, signal, varargin{:} );
          coh = SignalContainer.get_trial_by_time_double( coh );
          mins = min( [spike.trial_stats.min, signal.trial_stats.min], [], 2 );
          maxs = max( [spike.trial_stats.max, signal.trial_stats.max], [], 2 );
          spike.data = coh;
          spike.trial_stats.min = mins;
          spike.trial_stats.max = maxs;
          site_str = [ 'site__' num2str(i) ];
          spike = require_fields( spike, 'sites' );
          spike.labels = set_field( spike.labels, 'sites', site_str );
          spike_range = spike.trial_stats.range;
          signal_range = signal.trial_stats.range;
          spike.trial_stats.range = max( [spike_range, signal_range], [], 2 );
          store{i} = spike;
        end
        store = extend( store{:} );
        freqs = freqs{1};
        store = update_frequencies( store, freqs(:, 1) );
      end
    end
    
    %{
        INTER-OBJECT COMPATIBILITY
    %}
    
    function tf = time_props_match(obj, B)
      
      %   TIME_PROPS_MATCH -- True if the sample-rate, start, stop,
      %     window-size, and step-sizes match between objects.
      %
      %     IN:
      %       - `B` (/any/) -- Values to test. Returns false if `B` is not
      %         a SignalContainer.
      %     OUT:
      %       - `tf` (logical) |SCALAR| -- True if the time-properties
      %         match between objects.
      
      tf = false;
      if ( ~isa(B, 'SignalContainer') ), return; end;
      tf = isequal( get_time_props(obj), get_time_props(B) );
    end
    
    function tf = window_props_match(obj, B)
      
      %   WINDOW_PROPS_MATCH -- True if the start, stop, window-size, and 
      %     step-sizes match between objects.
      %
      %     IN:
      %       - `B` (/any/) -- Values to test. Returns false if `B` is not
      %         a SignalContainer.
      %     OUT:
      %       - `tf` (logical) |SCALAR| -- True if the time-properties
      %         match between objects.
      
      tf = false;
      if ( ~isa(B, 'SignalContainer') ), return; end;
      a_props = get_time_props( obj );
      b_props = get_time_props( B );
      %   remove sample rate
      a_props(end) = [];
      b_props(end) = [];
      tf = isequal( a_props, b_props );
    end
    
    %{
        GENERIC INTER-OBJECT FUNCTIONS
    %}
    
    function obj = append(obj, B)
      
      %   APPEND -- Append one SignalContainer to another.
      %
      %     Both objects must be SignalContainers; see `help
      %     Container/append` for more info.
      %
      %     IN:
      %       - `B` (SignalContainer) -- Object to append.
      
      assert( isa(B, 'SignalContainer'), ['It is only possible to append' ...
        , ' SignalContainers; input was a ''%s'''], class(B) );
      if ( isempty(B) ), return; end;
      obj = append@Container( obj, B );
      obj.trial_ids = [obj.trial_ids; B.trial_ids];
      fields = fieldnames( obj.trial_stats );
      for i = 1:numel(fields)
        own = obj.trial_stats.(fields{i});
        other = B.trial_stats.(fields{i});
        obj.trial_stats.(fields{i}) = [own; other];
      end
    end
    
    %{
        OPERATIONS
    %}
    
    function new_obj = do_per_day(obj, func, varargin)
      
      %   DO_PER_DAY -- Helper alias to call a function per each day
      %     present in the object.
      %
      %     IN:
      %       - `func` (function_handle) -- Handle to the function to
      %         call.
      %       - `varargin` (/any/) -- Any additional inputs to pass with
      %         each call to `func`.
      %     OUT:
      %       - new_obj (SignalContainer, Container) -- Result of the
      %       repeated calls to `func`.
      %
      %     See also Container/do_per
      
      new_obj = do_per( obj, 'days', func, varargin{:} );
    end
    
    function new_obj = subtract_across_mult(obj, varargin)
      
      %   SUBTRACT_ACROSS_MULT -- Call subtract_across continuously with
      %     the specified (selector1, selector2, setas) triplets.
      %
      %     See help `SignalContainer/subtract_across` for more info.
      %
      %     IN:
      %       - `varargin` (cell array) -- Variable number of arguments
      %         passed as cell arrays of triplets, as above.
      %     OUT:
      %       - `new_obj` (SignalContainer) -- New object with the
      %       subtracted values appended in the order in which they were
      %       input.
      %
      %     EX:
      %
      %     %   get (both-self) and (other-none) measures:
      %
      %     new_obj = ...
      %       subtract_across_mult( obj, {'self','both','self:both'},
      %       {'other', 'none', 'other:none'} );
      
      new_obj = Container();
      for i = 1:numel(varargin)
        assert( numel(varargin{i}) == 3, ['You must specify a `set_as`' ...
          , ' parameter when using subtract_across_mult'] );
        sel1 = varargin{i}{1};
        sel2 = varargin{i}{2};
        current = subtract_across( obj, sel1, sel2, varargin{i}{3} );
        new_obj = append( new_obj, current );
      end
    end
    
    function obj = subtract_across(obj, sel1, sel2, set_as)
      
      %   SUBTRACT_ACROSS -- Select two data-sets from the object, and
      %     subtract one from the other.
      %
      %     Both selectors must be drawn from the same field / category,
      %     and the resulting objects must be of compatible dimensions.
      %
      %     IN:
      %       - `sel1` (char) -- First label to select.
      %       - `sel2` (char) -- Second label to select. Both labels must
      %         be drawn from the same field / category.
      %       - `set_as` (char) |OPTIONAL| -- Optionally specify a label to
      %         identify the subtracted values. Defaults to 'all__`field`'
      %         where `field` is the name of the field from which the
      %         selectors were drawn.
      %
      %     Ex:
      %
      %     % subtract post drug values from pre drug values:
      %     
      %     obj = subtract_across( obj, 'post', 'pre', 'postMinusPre' );
      
      [sel1_ind, field1] = where( obj, sel1 );
      [sel2_ind, field2] = where( obj, sel2 );
      
      assert( ~any([isequal(field1{1}, -1), isequal(field2{1}, -1)]), ...
        'At least one of the specified selectors is not in the object' );
      assert( isequal(field1, field2), ['Selectors must be drawn from the same' ...
        , 'category/field'] );
      assert( numel(field1) == 1 && numel(field2) == 1, ['Specify only a single' ...
        , ' selector per condition'] );
      
      A = keep( obj, sel1_ind );
      B = keep( obj, sel2_ind );
      
      subtracted = opc( A, B, field1(1), @minus );
      trial_stats = A.trial_stats;
      stat_fields = fieldnames( trial_stats );
      for i = 1:numel(stat_fields)
        current_a = trial_stats.(stat_fields{i});
        current_b = B.trial_stats.(stat_fields{i});
        trial_stats.(stat_fields{i}) = current_a - current_b;
      end
      obj.data = subtracted.data;
      obj.labels = subtracted.labels;
      obj.dtype = subtracted.dtype;
      obj.trial_stats = trial_stats;
      if ( nargin < 4 ), return; end;
      obj.labels = ...
        replace( obj.labels, ['all__' field1{1}], set_as );
    end    
    
    %{
        UTIL
    %}
    
    function obj = get_freq_by_time_data(obj)
      
      %   GET_FREQ_BY_TIME_DATA -- Convert the averaged-data in the object
      %     to a 1x1 cell, whose data are an MxN matrix of M frequencies
      %     and N time-bins.
      %
      %     Data in the object must be the result of an analysis routine
      %     and contain three dimensions: trials-by-frequencies-by-time.
      %     BUT the trial dimensions must be == 1.
      
      assert( shape(obj, 1) == 1, ['There can only be one trials'' worth' ...
        , ' of data in the object; there were %d rows'], shape(obj, 1) );
      assert( ndims(obj.data) == 3, ['The object must have three-dimensional' ...
        , ' (trials-by-frequency-by-time) data'] );
      new_data = zeros( size(obj.data, 2), size(obj.data, 3) );      
      new_data(:, :) = obj.data(1, :, :);
      obj.data = { new_data };
    end
    
    function obj = to_signal_object(obj)
      
      %   TO_SIGNAL_OBJECT -- Convert a SignalContainer to a SignalObject.
      
      new = to_data_object( obj );
      obj = SignalObject( new, obj.fs, obj.start:obj.step_size:obj.stop );      
    end
    
    function obj = only_matching(obj, B, fields, labs)
      
      %   ONLY_MATCHING -- Only retain labels that are present in a
      %     second object.
      %
      %     IN:
      %       - `B` (SignalContainer, Container) -- Object to match.
      %       - `fields` (cell array of strings, char) -- Fields from which
      %         to draw labels to match.
      %       - `labs` (cell array of strings) |OPTIONAL| -- Optionally
      %         specify the label combinations to match. Must be an MxN
      %         cell array of M string-combinations in N fields (as e.g.
      %         returned by `combs()`).
      %     OUT:
      %       - `matched` (Container, SignalContainer) -- Object containing
      %         only the labels in the `fields` of `B`.
      
      Assertions.assert__isa( B, 'Container' );
      fields = Labels.ensure_cell( fields );
      if ( nargin < 4 ), labs = combs( obj, fields ); end
      labs = Labels.ensure_cell( labs );
      Assertions.assert__is_cellstr( fields );
      Assertions.assert__is_cellstr( labs );
      assert__contains_fields( obj.labels, fields );
      assert__contains_fields( B.labels, fields );
      assert( numel(fields) == size(labs, 2), ['The number of fields' ...
        , ' must match the number of columns of labels. Expected labels' ...
        , ' to have %d columns; %d were present.'], numel(fields) ...
        , size(labs, 2) );
      for i = 1:size(labs, 1)
        ind_b = where( B, labs(i, :) );
        if ( ~any(ind_b) )
          ind_a = where( obj, labs(i, :) );
          obj = keep( obj, ~ind_a );
        end
      end
    end
    
    function matched = match(obj, B)
      
      %   MATCH -- Match the contents of a Container to the current
      %     Container, based on the labels in each.
      %
      %     The second Container must contain all of the label combinations
      %     in the first Container; it can contain additional combinations,
      %     but these will be discarded. An error is thrown if a label
      %     combination in the present object is not found in the second
      %     object. Fields not shared between the two-objects will be
      %     removed; if no fields are shared, an empty object is returned.
      %
      %     IN:
      %       - `B` (SignalContainer, Container) -- Object to match to the
      %         current object.
      %     OUT:
      %       - `matched` (SignalContainer, Container) -- Object
      %         containining elements of `B` ordered to match the set of
      %         labels in the first object.
      
      assert( isa(B, 'Container'), 'Input must be a Container; was a ''%s''' ...
        , class(B) );
      matched = Container();
      common_fields = intersect( field_names(obj), field_names(B) );
      if ( isempty(common_fields) )
        matched = keep_one( obj, 1 );
        matched = keep( matched, false ); return;
      else
        obj = rm_fields( obj, setdiff(field_names(obj), common_fields) );
        B = rm_fields( B, setdiff(field_names(B), common_fields) );
      end
      while ( ~isempty(obj) )
        ref_struct = struct( 'type', '()', 'subs', {{1}} );
        current = subsref( obj, ref_struct );
        labs = flat_uniques( current.labels );
        current_b = only( B, labs );
        if ( isempty(current_b) )
          error( 'The label sets do not match between objects' );
        end
        matched = append( matched, current_b );
        ind = where( obj, labs );
        obj = keep( obj, ~ind );
      end
    end
    
    function obj = nanmedian(obj, dim)
      
      %   NANMEDIAN -- Return an object whose data are a median across a 
      %     given dimension, excluding NaN.
      %
      %     IN:
      %       - `dim` (double) |OPTIONAL| -- Dimension specifier. Defaults
      %         to 1.
      %
      %     See also Container/row_op, Container/n_dimension_op
      
      if ( nargin < 2 ), dim = 1; end;
      if ( isequal(dim, 1) )
        obj = row_op( obj, @nanmedian, 1 );
      else obj = n_dimension_op( obj, @nanmedian, dim );
      end
    end
    
    %{
        PROPERTY SETTING
    %}
    
    function obj = set_property(obj, prop, values)
      
      %   SET_PROPERTY -- Overloaded Container method to allow updating of
      %     SignalContainer-specific properties.
      %
      %     Ensures trial_ids are of the appropriate dimension.
      %
      %     IN:
      %       - `prop` (char) -- Name of property to set.
      %       - `values` (/any/) -- Values to assign to the property.
      
      if ( any(strcmp({'data', 'labels', 'dtype'}, prop)) )
        obj = set_property@Container( obj, prop, values );
        return;
      end
      switch ( prop )
        case 'trial_ids'
          assert( numel(values) == shape(obj, 1), ['When overwriting' ...
            , ' trial_ids, the new trial_ids must match the number of rows' ...
            , ' in the object. Current number of rows is %d; attempted to' ...
            , ' assign %d values'], shape(obj, 1), numel(values) );
        case 'trial_stats'
          assert( isstruct(values), ['The trial_stats property must be a struct;' ...
            , ' attempted to assign a ''%s'''], class(values) );
          assert__properly_dimensioned_trial_stats( obj, values );
      end
      obj.(prop) = values;
    end
    
    function obj = update_range(obj)
      
      %   UPDATE_RANGE -- Update the `range` field of the trial_stats
      %     struct of the object.
      
      data = obj.data;
      mins = min( data, [], 2 );
      maxs = max( data, [], 2 );
      obj.trial_stats.range = maxs - mins;
      assert__properly_dimensioned_trial_stats( obj, obj.trial_stats );
    end
    
    function obj = update_min(obj)
      
      %   UPDATE_MIN -- Update the `min` field of trial_stats struct.
      
      obj.trial_stats.min = min( obj.data, [], 2 );
      assert__properly_dimensioned_trial_stats( obj, obj.trial_stats );
    end
    
    function obj = update_max(obj)
      
      %   UPDATE_MAX -- Update the `max` field of trial_stats struct.
      
      obj.trial_stats.max = max( obj.data, [], 2 );
      assert__properly_dimensioned_trial_stats( obj, obj.trial_stats );
    end
    
    function arr = get_time_props(obj)
      
      %   GET_TIME_PROPS -- Get the time properties of a SignalContainer in
      %     one array.
      %
      %     OUT:
      %       - `arr` (double) -- Vector of the start-time, stop-time,
      %         step_size, window-size, and sample-rate of the object.
      
      arr = [obj.start, obj.stop, obj.step_size, obj.window_size, obj.fs];
    end
    
    function series = get_time_series(obj)
      
      %   GET_TIME_SERIES -- Get a vector of time-stamps corresponding to
      %     each sample point in the 3rd dimension.
      %
      %     OUT:
      %       `series` (double) -- Vector of time-stamps, starting at
      %       obj.start, stepped by obj.step_size, and ending at obj.stop.
      
      assert( ~isnan(obj.start), 'Time properties have not been defined.' );
      series = obj.start:obj.step_size:obj.stop;            
    end
    
    function arr = get_props(obj)
      
      %   GET_PROPS -- Return public properties of the object.
      
      arr = { obj.data, obj.labels, obj.fs, [obj.start, obj.stop] ...
        , [obj.step_size, obj.window_size], obj.trial_ids, obj.frequencies };
    end
    
    function obj = refresh(obj)
      
      %   REFRESH -- Return a newly-constructed SignalContainer from the
      %     current object's properties.
      %
      %     This is useful if you've edited the default params struct in
      %     this classdef .m file, and wish to apply those defaults to an
      %     object that was constructed before the file was changed.
      
      props = get_props( obj );
      obj = SignalContainer( props{:} );
    end
    
    function obj = update_frequencies(obj, f)
      
      %   UPDATE_FREQUENCIES -- Overwrite the current `frequencies`
      %     property with the desired values.
      %
      %     IN:
      %       - `f` (double) -- Vector of frequencies present in the
      %         object.
      
      obj.frequencies = f;
    end
    
    function obj = update_ids(obj, ids)
      
      %   UPDATE_IDS -- Assign new values to the trial_ids property.
      %
      %     New ids must have the same number of elements as there are rows
      %     in the object.
      %
      %     IN:
      %       - `ids` (double) -- Vector of new trial_ids.
      
      assert( numel(ids) == shape(obj, 1), ['The number of ids must match' ...
        , ' the number of rows in the object'] );
      obj.trial_ids = ids;
    end
    
    %{
        PLOTS
    %}
    
    function h = scatter(obj, B, within, varargin)
      
      %   SCATTER -- Generate scatter plots that scatter the data of two
      %     SignalContainers to the appropriate specificity.
      %
      %     Both objects must have equivalent shapes and labels.
      %
      %     IN:
      %       - `within` (cell array of strings, char, []) -- Each unique
      %         combination of labels in these fields will receive its own
      %         subplotted panel. If [], the resulting scatter plot will
      %         not be subplotted; all values in the object will be
      %         scattered with those of `B`.
      %       - `B` (Container, SignalContainer) -- Object whose labels are
      %         to be matched, and whose data are to be scattered on the
      %         y-axis.
      %     OUT:
      %       - `h` (figure handle) -- Handle to the figure.
      
      params = struct( ...
          'shape', [] ...
        , 'yLim', [] ...
        , 'xLim', [] ...
        , 'xLabel', [] ...
        , 'yLabel', [] ...
        , 'addFit', true ...
        , 'addSignificanceStar', true ...
      );
      params = parsestruct( params, varargin );
      assert( isa(B, 'Container'), 'Input must be a Container; was a ''%s''' ...
        , class(B) );
      assert( eq(obj.labels, B.labels), ['The label objects in the two' ...
        , ' objects must match'] );
      assert( all(cellfun(@(x) ndims(x.data) == 2, {obj, B})) ...
        , ['Data in both objects must be an MxN array of M trials N' ...
        , ' sample points. Perhaps you meant to call time_freq_mean()?'] );
      if ( isempty(within) )
        inds = { true(shape(obj, 1), 1) };
        within = field_names( obj );
      else inds = get_indices( obj, within );
      end
      if ( isempty(params.shape) )
        params.shape = [1, numel(inds)];
      else
        assert( params.shape(1)*params.shape(2) >= numel(inds), ['When specifying' ...
          , ' dimensions for the subplot, the number of rows * number of columns' ...
          , ' must be greater than or equal to the number of unique' ...
          , ' combinations. The minimum for this label-set is %d'] ...
          , numel(inds) );
      end
      for i = 1:numel(inds)
        extr = keep( obj, inds{i} );
        extr_B = only( B, flat_uniques(extr.labels) );
        unqs = strjoin( flat_uniques(extr.labels, within), ' | ' );
        subplot( params.shape(1), params.shape(2), i );
        hold off;
        h = scatter( extr.data, extr_B.data );
        title( unqs );
        if ( ~isempty(params.yLim) ), ylim( params.yLim ); end;
        if ( ~isempty(params.xLabel) ), xlabel( params.xLabel); end;
        if ( ~isempty(params.yLabel) ), ylabel( params.yLabel ); end;
        if ( params.addFit )
          fitted = polyfit( extr.data, extr_B.data, 1 );
          hold on;
          plot( extr.data, polyval(fitted, extr.data) );
          if ( params.addSignificanceStar )
            [~, p] = corr( extr.data, extr_B.data );
            if ( p < .05 )
              sig_x = mean( extr.data );
              sig_y = mean( extr_B.data );
              plot( sig_x, sig_y, 'k*', 'markersize', 5 );
            end
          end
        end
      end
    end
    
    function h = histogram(obj, within, varargin)
      
      %   HISTOGRAM -- Create a subplotted histogram to the desired
      %     specificity.
      %
      %     Data in the object must be an MxN matrix of M trials and N
      %     analysis values; e.g., those derived from a call to
      %     time_freq_mean().
      %
      %     IN:
      %       - `within` (cell array of strings, char, []) -- Each unique
      %         combination of labels in these fields will receive its own
      %         subplotted panel. If [], the resulting plot is not a
      %         subplot, but instead a single plot showing a histogram of
      %         all data in the object.
      %       - `varargin` ('name', value pairs) -- Various 'name', value
      %         paired inputs. See the params struct below for possible
      %         'name's.
      %           - 'shape' controls the number of rows and columns in the
      %             subplot.
      %           - 'nBins' controls the number of bins to use in the
      %             histogram.
      %     OUT:
      %       - `h` (figure handle) -- Handle to the histogram plot object.
      
      params = struct( ...
          'nBins', 50 ...
        , 'shape', [] ...
        , 'yLim', [] ...
        , 'xLim', [] ...
      );
      params = parsestruct( params, varargin );
      assert( ndims(obj.data) == 2, ['Call this function after taking' ...
        , ' a mean over time and frequency'] );
      if ( isempty(within) )
        inds = { true(shape(obj, 1), 1) };
        within = field_names( obj );
      else inds = get_indices( obj, within );
      end
      if ( isempty(params.shape) )
        params.shape = [1, numel(inds)]; 
      else
        assert( params.shape(1)*params.shape(2) >= numel(inds), ['When specifying' ...
          , ' dimensions for the subplot, the number of rows * number of columns' ...
          , ' must be greater than or equal to the number of unique' ...
          , ' combinations. The minimum for this label-set is %d'] ...
          , numel(inds) );
      end
      if ( isempty(params.xLim) ), auto_x = get_x_limit( obj, inds ); end;
      for i = 1:numel(inds)
        extr = keep( obj, inds{i} );
        unqs = strjoin( flat_uniques(extr.labels, within), ' | ' );
        subplot( params.shape(1), params.shape(2), i );
        h = histogram( extr.data, params.nBins );
        title( unqs );
        if ( ~isempty(params.yLim) ), ylim( params.yLim ); end;
        if ( ~isempty(params.xLim) )
          xlim( params.xLim ); 
        else xlim( auto_x );
        end
      end
      %   automatically set x-limits
      function lim = get_x_limit(object, indices)
        mins = [];
        maxs = [];
        for k = 1:numel(indices)
          extract = keep( object, indices{k} );
          if ( k == 1 )
            mins = min( extract.data );
            maxs = max( extract.data );
            continue;
          end
          mins = min( [mins, min(extract.data)] );
          maxs = max( [maxs, max(extract.data)] );
        end
        lim = [mins, maxs];
      end
    end
    
    function h = spectrogram(obj, within, varargin)
      
      %   SPECTROGRAM -- Plot a subplotted time-by-frequency spectrogram
      %     for each combination of unique labels present in `within`.
      %
      %     The data in the object must be an MxNxP matrix of M trials, N
      %     frequencies, and P time bins. N must match the number of
      %     elements of the frequencies property of the object; P must
      %     match the number of time-bins in the time-series of the object.
      %     ADDITIONALLY, it is an error for a label-set identified by
      %     `within` to result in an object with more than one trial. I.e.,
      %     each object specified by the combination of labels in `within`
      %     must be a 1xNxP matrix.
      %
      %     IN:
      %       - `within` (cell array of strings, char, []) -- Each unique
      %         combination of labels in these fields will receive its own
      %         subplotted panel. If [], there must be only one trial's
      %         worth of data in the object.
      %       - `varargin` ('name', value pairs) -- Overwrite the default
      %         values of the params struct below by specifying inputs in
      %         'name', value pairs.
      %     OUT:
      %       - `h` (figure handle) -- Handle to the plot object.
      
      params = struct( ...
          'time', [] ...
        , 'frequencies', [] ...
        , 'clims', [] ...
        , 'shape', [] ...
        , 'colorMap', 'jet' ...
        , 'gaussian', struct( 'active', true, 'strength', 2 ) ...
        , 'invert', true ...
        , 'xLabel', [] ...
        , 'yLabel', [] ...
        , 'title', [] ...
        , 'titleCategories', {{'regions', 'outcomes', 'days', 'drugs', 'trialtypes', 'administration'}} ...
        , 'timeLabelStep', 10 ...
        , 'freqLabelStep', 10 ...
        , 'fullScreen', false ...
        , 'rectangle', [] ...
        , 'linesEvery', [] ...
      );

      params = parsestruct( params, varargin );
      assert( ndims(obj.data) == 3, ['The object must have data that are' ...
        , ' an MxNxP matrix of M trials, N frequencies, and P time-bins'] );
      assert( numel(obj.frequencies) == size(obj.data, 2), ['The frequencies' ...
        , ' in the object do not properly correspond to the dimensions of the' ...
        , ' object''s data.'] );
      time_series = obj.start:obj.step_size:obj.stop;
      assert( numel(time_series) == size(obj.data, 3), ['The time series in the object' ...
        , ' does not properly correspond to the dimensions of the object''s' ...
        , ' data'] );
      if ( isempty(within) )
        assert( shape(obj, 1) == 1, ['You must specify `within` if the number' ...
          , ' of trials in the object is greater than 1'] );
        inds = { true };
        within = field_names( obj );
      else inds = get_indices( obj, within );
      end
      if ( isempty(params.shape) )
        params.shape = [1, numel(inds)]; 
      else
        assert( params.shape(1)*params.shape(2) >= numel(inds), ['When specifying' ...
          , ' dimensions for the subplot, the number of rows * number of columns' ...
          , ' must be greater than or equal to the number of unique' ...
          , ' combinations. The minimum for this label-set is %d'] ...
          , numel(inds) );
      end
      subps = gobjects( 1, numel(inds) );
      for k = 1:numel(inds)
        freqs = obj.frequencies;
        time = time_series;
        extr = keep( obj, inds{k} );
        subps(k) = subplot( params.shape(1), params.shape(2), k );
        assert( shape(extr, 1) == 1, ['The object must only have 1 row (i.e.,' ...
          , ' be a mean across trials). Take a mean across trials before plotting.'] );
        data = zeros( numel(freqs), numel(time) );
        data(:, :) = extr.data;
        %   get the desired frequency limits
        if ( ~isempty(params.frequencies) )
          freq_ind = freqs <= params.frequencies(2) & freqs >= params.frequencies(1);
          assert( any(freq_ind), 'The specified frequencies are out of bounds' );
        else freq_ind = true( size(freqs) );
        end
        %   get the desired time limits
        if ( ~isempty(params.time) )
          time_ind = time <= params.time(2) & time >= params.time(1);
          assert( any(time_ind), 'The specified times are out of bounds' );
        else time_ind = true( size(time) );
        end
        %   index according to desired frequency and time limits
        freqs = freqs( freq_ind );
        time = time( time_ind );
        data = data( freq_ind, time_ind );
        freqs = repmat( freqs(:), 1, size(data, 2) );
        %   plot from 0 at the bottom of the y-axis
        if ( params.invert ), freqs = flipud( freqs ); data = flipud( data ); end;
        %   add a gaussian blur if desired
        if ( params.gaussian.active )
          data = imgaussfilt( data, params.gaussian.strength );
        end
        %   actual plotting
        if ( ~isempty(params.clims) )
          h = imagesc( freqs, 'CData', data, params.clims );
        else h = imagesc( freqs, 'CData', data );
        end      
        colormap( params.colorMap );
        color_bar = colorbar;
        %   labeling      
        if ( ~isempty(params.xLabel) ), xlabel( params.xLabel ); end
        if ( ~isempty(params.yLabel) ), ylabel( color_bar, params.yLabel ); end
        if ( ~isempty(params.title) )
          title( params.title ); 
        else
          labels = uniques( extr, within );
          labels = cellfun( @(x) x', labels, 'un', false ); 
          labels = [ labels{:} ];
          title_str = strjoin( labels, ' | ' );
          title_str = strrep( title_str, '__', ' ' );
          title_str = strrep( title_str, '_', ' ' );
          title( title_str );
        end
        if ( contains_fields(extr.labels, 'epochs') )
          epoch = char( unique(get_fields(extr.labels, 'epochs')) );
        else epoch = 'start';
        end
        xlabel( sprintf('Time (ms) from %s', epoch) );
        ylabel( 'Frequency (hz)' );
        %   time tick labels
        label_time = get_tick_labels( time, params.timeLabelStep );
        label_freqs = get_tick_labels( freqs(:, 1), params.freqLabelStep );

        set( gca, 'xtick', 1:numel(label_time) );
        set( gca, 'xticklabel', label_time );
        set( gca,'ytick', 1:numel(label_freqs) );
        set( gca, 'yticklabel', label_freqs );
        if ( ~isempty(params.rectangle) )
          rects = params.rectangle;
          rects = Labels.ensure_cell( rects );
          for j = 1:numel(rects)
            rect = rects{j};
            rect_time = [ find(time == rect(1)), find(time == rect(2)) ];
            differences = abs( [freqs(:,1)-rect(3), freqs(:,1)-rect(4)] );
            rect_freqs = [ find( differences(:,1) == min(differences(:,1)) ) ...
              , find( differences(:, 2) == min(differences(:, 2)) ) ];
            rect_time = sort( rect_time );
            rect_freqs = sort( rect_freqs );
            rect_x = rect_time(1);
            rect_y = rect_freqs(1);
            rect_w = rect_time(2) - rect_time(1);
            rect_h = rect_freqs(2) - rect_freqs(1);
            rectangle( 'Position', [rect_x, rect_y, rect_w, rect_h] );
          end
        end
        if ( ~isempty(params.linesEvery) )
          lines_every = params.linesEvery;
          line_xs = lines_every(1):lines_every(2):numel(time);
          ylims = get( gca, 'ylim' );
          line_ys = repmat( ylims(:), 1, numel(line_xs) );
          line_xs = [ line_xs(:)'; line_xs(:)' ];
          hold on;
          plot( line_xs, line_ys, 'w' );
          hold off;
        end
      end        
      if ( params.fullScreen )
        set( gcf, 'units', 'normalized', 'outerposition', [0 0 1 1] );
      end
      %   match limits
      if ( isempty(params.clims) )
        lims = cell(1, numel(subps) );
        for k = 1:numel(subps)
          lims{k} = get( subps(k), 'Clim' );
        end
        mins = min( cellfun(@(x) x(1), lims) );
        maxs = max( cellfun(@(x) x(2), lims) );
        arrayfun( @(x) caxis(x, [mins, maxs]), subps );
      end
      function labs = get_tick_labels( axis_values, label_step )
        
        %   GET_TICK_LABELS -- Utility function which creates an x- or
        %     y-tick label cell array of rounded string representations of
        %     the values in `axis_values`.
        
        labs = repmat( {''}, 1, numel(axis_values) );
        for i = 1:label_step:numel(axis_values)
          labs{i} = num2str( round(axis_values(i)) );
        end
        labs{end} = num2str( round(axis_values(end)) );
        zero_index = axis_values == 0;
        if ( any(zero_index) ), labs{zero_index} = '0'; end;
      end      
    end
    
    %{
        ASSERTIONS
    %}
    
    function assert__properly_dimensioned_trial_stats(obj, trial_stats)
      
      %   ASSERT__PROPERLY_DIMENSIONED_TRIAL_STATS -- Throw an error if any
      %     of the fields of a given trial_stats struct do not match the
      %     number of rows (trials) in the object.
      %
      %     IN:
      %       - `trial_stats` (struct) -- Struct to validate.
      
      assert( isstruct(trial_stats), ['Expected trial_stats to be a struct; was a' ...
        , ' ''%s'''], class(trial_stats) );
      n_trials = size( obj.data, 1 );
      fields = fieldnames( trial_stats );
      for i = 1:numel(fields)
        assert( numel(trial_stats.(fields{i})) == n_trials, ['Each per-trial statistic' ...
          , ' must match the number of trials (rows) in the object'] );
      end
    end
    
    function assert__time_props_match(obj, B)
      
      %   ASSERT__TIME_PROPS_MATCH -- Throw an error if an input is not a
      %     SignalContainer with time-properties that match those of the
      %     current object.
      %
      %     IN:
      %       - `B` (/any/) -- Values to test.
      
      assert( isa(B, 'SignalContainer'), ['Expected a SignalContainer as input;' ...
        , ' was a ''%s'''], class(B) );
      assert( time_props_match(obj, B), ['Time properties do not match between' ...
        , ' objects'] );
    end
    
    function assert__window_props_match(obj, B)
      
      %   ASSERT__WINDOW_PROPS_MATCH -- Ensure start, stop, window_size,
      %     and step_size properties are equivalent.
      
      assert( window_props_match(obj, B), ['Window properties do not match' ...
        , ' between objects.'] );
    end
    
    function assert__capable_of_coherence(obj, B)
      
      %   ASSERT__CAPABLE_OF_COHERENCE -- Ensure two SignalContainers are
      %     compatible with a coherence analysis
      %
      %     IN:
      %       - B (/ANY/) -- Values to test.
      
      assert( isa(B, 'SignalContainer'), ['Expected a SignalContainer as input;' ...
        , ' was a ''%s'''], class(B) );
      assert( shape(obj, 1) == shape(B, 1), ['The shapes of the two' ...
        , ' containers must match'] );
      assert__dtypes_match( obj, B );
      assert( isequal(obj.dtype, 'double'), ['Signals must be stored in a plain' ...
        , ' matrix'] );
      assert__time_props_match( obj, B );      
    end
    
    function assert__capable_of_sfcoherence(obj, B)
      
      %   ASSERT__CAPABLE_OF_SFCOHERENCE -- Ensure two SignalContainers are
      %     compatible with a spike-field coherence analysis
      %
      %     IN:
      %       - B (/ANY/) -- Values to test.
      
      assert( isa(B, 'SignalContainer'), ['Expected a SignalContainer as input;' ...
        , ' was a ''%s'''], class(B) );
      assert( shape(obj, 1) == shape(B, 1), ['The shapes of the two' ...
        , ' containers must match'] );
      assert( strcmp(obj.dtype, 'logical'), ['The spiking data in' ...
        , ' the first object must be a logical PSTH matrix; was a ''%s''.'] ...
        , obj.dtype );
      assert( strcmp(B.dtype, 'double'), ['The continuous data must be' ...
        , ' a double matrix; was a ''%s''.'], B.dtype );
      assert__window_props_match( obj, B );  
    end
    
    function assert__capable_of_norm_power(obj, B)
      
      %   ASSERT__CAPABLE_OF_NORM_POWER -- Ensure two SignalContainers are
      %     compatible with a normalized power analysis
      %
      %     IN:
      %       - B (/ANY/) -- Values to test.
      
      assert( isa(B, 'SignalContainer'), ['Expected a SignalContainer as input;' ...
        , ' was a ''%s'''], class(B) );
      assert( shape(obj, 1) == shape(B, 1), ['The shapes of the two' ...
        , ' containers must match'] );
      assert__dtypes_match( obj, B );
      assert( isequal(obj.dtype, 'double'), ['Signals must be stored in a plain' ...
        , ' matrix'] );
      assert( B.stop - B.start == 0, ['The normalizizing object must only have' ...
        , ' one time window''s worth of data'] );
    end
  end
  
  methods (Static = true)
    
    %{
        STATIC ASSERTIONS
    %}
    
    function assert__within_bounds(x, b, kind)
      assert( numel(x) == 2, 'Specify %s as a two-element vector.', kind );
      assert( x(1) < x(2), ['The first element of %s must be less than the' ...
        , ' second.'], kind );
      assert( min(b) <= x(1), 'The specified %s are out of bounds.', kind );
      assert( max(b) >= x(2), 'The specified %s are out of bounds.', kind );
    end
      
    function assert__dimensions_match(x, b, kind)
      assert( numel(x) == b, ['Dimension mismatch between the data' ...
        , ' and %s.'''], kind );
    end
    
    %{
        BOUNDING
    %}
    
    function ids = get_in_bounds_trial_ids(signals, threshold)
      
      %   GET_IN_BOUNDS_TRIAL_IDS -- Obtain a vector of unique trial-ids
      %     that correspond to trials for which the range is less than or
      %     equal to the given threshold.
      %
      %     IN:
      %       - `signals` (SignalContainer) -- Object whose
      %         data are an MxN matrix of M trials and N sample points.
      %       - `threshold` (double) |SCALAR| -- Number specifying the
      %         maximum range of data, per-trial.
      
      ids = signals.trial_ids;
      assert( numel(ids) == shape(signals, 1), ['The ids do not properly' ...
        , ' correspond to the inputted signals.'] );
      data = signals.data;
      mins = min( data, [], 2 );
      maxs = max( data, [], 2 );
      in_bounds = ( maxs - mins ) <= threshold;
      ids = unique( ids(in_bounds) );
    end
    
    function id_container = get_trial_ids_per_day(signals)
      
      %   GET_TRIAL_IDS_PER_DAY -- Call the function dsp__get_trial_ids
      %     separately for each day of data present the given signals, and
      %     return a container whose data are the per-day ids, and whose
      %     labels are the corresponding days.
      %
      %     IN:
      %       - `signals` (Container, SignalContainer) -- Object with a
      %         'days' category.
      %     OUT:
      %       - `id_container` (Container, SignalContainer) -- Object whose
      %         data are trial_ids as obtained from dsp__get_trial_ids(),
      %         and whose labels are the associated days. Will be of the
      %         same class as the inputted signals.
      
      assert( isa(signals, 'Container'), ['Signals must be a Container; was a' ...
        , ' ''%s'''], class(signals) );
      ref_struct = struct( 'type', '()', 'subs', 'days' );
      days = subsref( signals, ref_struct );
      id_container = Container();
      if ( isa(signals.labels, 'SparseLabels') )
        cats = unique( signals.labels.categories );
      else cats = signals.labels.fields;
      end
      cats( strcmp(cats, 'days') ) = [];
      for i = 1:numel(days)
        extr = only( signals, days{i} );
        ids = dsp__get_trial_ids( extr );
        extr.data = ids;
        extr = collapse( extr, cats );
        id_container = append( id_container, extr );
      end
    end
    
    %{
        ANALYSIS UTILITIES
    %}
    
    function arr = get_trial_by_time_double(measure)
      
      %   GET_TRIAL_BY_TIME_DOUBLE -- Convert the output from an anslysis
      %     measure to an MxNxP matrix of M trials, N frequencies, and P
      %     time-bins.
      %
      %     IN:
      %       - `measure` -- (cell array of cell arrays) -- Output from
      %         coherence(), raw_power(), or norm_power()
      %     OUT:
      %       - `arr` -- (double) -- Reformatted array.      
      
      assert( iscell(measure), ['Measure must be a cell array derived from' ...
        , ' an analysis function.'] );
      n_freqs = size( measure{1}, 1 );
      n_trials = size( measure{1}, 2 );
      n_bins = size( measure, 2 );
      arr = zeros( n_trials, n_freqs, n_bins );
      for i = 1:n_bins
        arr( :, :, i ) = measure{i}';
      end
    end
    
    function arr = get_trial_by_time_cell(measure)
      
      %   GET_TRIAL_BY_TIME_ARRAY -- Convert the output from an analysis
      %     measure to an MxT cell array of M trials and T time-bins.
      %
      %     Each cell(i,j) is a 1xF vector of values where each F(f)
      %     corresponds to obj.frequencies(f)
      %
      %     IN:
      %       - `measure` -- (cell array of cell arrays) -- Output from
      %         coherence(), raw_power(), or norm_power()
      %     OUT:
      %       - `arr` -- (cell array of cell array) -- Reformatted cell
      %         array.
      
      measure = cellfun( @(x) x', measure, 'un', false );
      arr = cell( size(measure{1}, 1), size(measure, 2) );
      for j = 1:size(measure{1}, 1)
        for l = 1:size(measure, 2)
          arr{j,l} = measure{l}(j, :);
        end
      end
    end
  end
end