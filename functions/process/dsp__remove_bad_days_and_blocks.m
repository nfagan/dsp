function obj = dsp__remove_bad_days_and_blocks( obj )

bad_days = { '02012017', '02022017' };
bad_days = day_prefix( bad_days );

days_for_first_block_removal = { '01172017' };
days_for_first_block_removal = day_prefix( days_for_first_block_removal );

days_to_correct = { '02132017', '02142017' };
days_to_correct = day_prefix( days_to_correct );

%   fix post vs. pre designation for `days_to_correct`.
for i = 1:numel(days_to_correct)
  ind = obj.where( {days_to_correct{i}, 'block__2'} );
  obj( 'administration', ind ) = 'post';
%   extr = obj.keep(ind);
%   obj = obj.keep(~ind);
%   extr( 'administration' ) = 'post';
%   obj = obj.append( extr );
end

%   remove `bad_days`
obj = obj.rm( bad_days );

%   remove the first block of `days_for_first_block_removal`.
for i = 1:numel(days_for_first_block_removal)
  ind = obj.where( {days_for_first_block_removal{i}, 'block__1'} );
  obj = obj.keep( ~ind );
end

end

function cells = day_prefix( cells )

cells = cellfun( @(x) ['day__' x], cells, 'un', false );

end