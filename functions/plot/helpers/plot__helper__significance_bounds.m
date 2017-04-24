%{
    zeros enclose ones
%}

function plot__helper__significance_bounds(h, bounds, freq_index, time_index)

assert( count(bounds,1) == 1, 'More than one bounds exist in the object' );

bounds = bounds.data{1}(freq_index, time_index);

assert( isa(bounds, 'logical'), 'Bounds must be a logical array' );

bounds = flipud( bounds );
% bounds = ~bounds;

% test_bounds = zeros(size(bounds));

% test_bounds(10:20,20:24) = 1; test_bounds = flipud(test_bounds);

[B,L] = bwboundaries( bounds, 'holes' ); hold on;

plot_bounds(B);

% figure; hold on;
% hold on;
% plot_starred_bounds(bounds);

end

function plot_bounds(B)

for k = 1:length(B)
   boundary = B{k};
   plot(boundary(:,2), boundary(:,1), 'k', 'LineWidth', .5)
end

end

function plot_shaded_bounds(bounds)

h = imagesc(bounds);
set(h, 'AlphaData', .1);

end

function plot_starred_bounds(bounds)
hold on;
for i = 1:size(bounds,2)
    indices = find(bounds(:,i));
    xs = zeros( size(indices) ); xs(:) = i;
    plot(xs, indices,'k*','markers',.5);
end
hold off;

% plot(bounds,'*','linewidth',.2);

end