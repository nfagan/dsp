function obj = dsp__post_process(obj)

%   add days

obj = dsp__fix_day_labels( obj );

%   fix session numbers

obj = fix_session_labels( obj );

%   namespace day labels: day__

obj = fix_day_labels( obj );

%   add pre / post index

obj = dsp__add_pre_post_index( obj );

end

function obj = fix_session_labels( obj )

sessions = obj( 'sessions' );
replaced_sessions = cellfun( @(x) x(1:10), sessions, 'un', false );

for i = 1:numel(sessions)
  obj = obj.replace( sessions{i}, replaced_sessions{i} );
end

end

function obj = fix_day_labels( obj )

days = obj( 'days' );
replaced_days = cellfun( @(x) ['day__' x], days, 'un', false );
for i = 1:numel(days)
  obj = obj.replace( days{i}, replaced_days{i} );
end

end