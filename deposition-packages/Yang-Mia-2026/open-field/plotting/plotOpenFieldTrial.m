function f = plotOpenFieldTrial(coordData, speedArray, centerFrames, BORDERLIMIT, FRAMERATE, XYSCALE, FILEID, TITLESTRING)
% Plot the open-field trajectory, colored by speed, and the center region.
% coordData: [x y] positions in mm, one frame per row.
% speedArray: speed for each plotted position, in mm/s.
% centerFrames: frame indices in the trajectory-based center region.
% BORDERLIMIT: fraction of the trajectory range at each border (default 0.15).
% FRAMERATE: recording frame rate (default 100); retained for this interface.
% XYSCALE: pixel size; retained for this interface. Positions are already in mm.
% FILEID and TITLESTRING: optional text for the plot.
% f: handle to the plot axes.

if size(coordData, 2) ~= 2
    warning('Expected coordinates with two columns: x and y.');
    f = [];
    return;
end
if ~exist('centerFrames', 'var'); centerFrames = []; end
if ~exist('BORDERLIMIT', 'var'); BORDERLIMIT = 0.15; end
if ~exist('FRAMERATE', 'var'); FRAMERATE = 100; end
if ~exist('XYSCALE', 'var'); XYSCALE = 1; end
if ~exist('FILEID', 'var'); FILEID = ''; end
if ~exist('TITLESTRING', 'var'); TITLESTRING = 'Open-field trajectory'; end

x = coordData(:, 1);
y = coordData(:, 2);
xBorder = range(x) * BORDERLIMIT;
yBorder = range(y) * BORDERLIMIT;
left = min(x) + xBorder;
right = max(x) - xBorder;
top = min(y) + yBorder;
bottom = max(y) - yBorder;
centerFraction = round(length(centerFrames) * 100 / length(coordData));

figure('Color', 'w');
f = gca;
hold on;
% Shade the trajectory-based center region beneath the path.
fill([left right right left], [top top bottom bottom], [0.88 0.95 0.94], ...
    'EdgeColor', 'none');
% A surface with coincident rows gives a speed-colored line without closing the path.
surface([x'; x'], [y'; y'], zeros(2, length(x)), [speedArray(:)'; speedArray(:)'], ...
    'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 2.2);
centerBoundary = plot([left right right left left], [top top bottom bottom top], '--', ...
    'Color', [0.15 0.45 0.45], 'LineWidth', 1.2);
legend(centerBoundary, 'Center boundary', 'Location', 'best', 'Box', 'off');

colormap(f, turbo);
c = colorbar;
c.Label.String = 'Speed (mm/s)';
xlabel('X (mm)');
ylabel('Y (mm)');
title(TITLESTRING, 'Interpreter', 'none');
subtitle(sprintf('%s | Center occupancy: %d%%', FILEID, centerFraction), 'Interpreter', 'none');
axis equal tight;
set(f, 'YDir', 'reverse', 'Box', 'off', 'TickDir', 'out', 'FontSize', 11);
hold off;
end
