function [centerFrames, borderFrames, centerFraction] = getCenterBorderFrames(coordData, BORDERLIMIT)
% Classify trajectory positions as center or border frames.
% coordData: tracked [x y] coordinates, one frame per row; positions should
% be finite. Both coordinates should use the same spatial units.
% Frames-in-columns input is transposed when there are more columns than rows.
% BORDERLIMIT: fraction of the observed x and y ranges assigned to the border
% on each side (default 0.15). The top-level analysis also defaults to 0.15.
%
% Boundaries are calculated from the minimum and maximum positions in this
% trajectory, not from measured arena walls. Positions exactly on a center
% boundary are counted as center frames.
% centerFrames and borderFrames: indices of frames in each region.
% centerFraction: center-frame percentage rounded to the nearest whole percent
% (0-100), despite the output name. All frames are included in the denominator.

if (~exist('BORDERLIMIT', 'var'))
    warning('BORDERLIMIT missing - defaulting to 15%%');
    BORDERLIMIT = 0.15;
end

% Arrange frames in rows, with x and y in columns.
if size(coordData, 2) > size(coordData, 1)
    coordData = coordData.';
end

if isempty(coordData) || size(coordData, 2) ~= 2
    warning('Coordinate data must contain frames and two coordinates.');
    centerFrames = [];
    borderFrames = [];
    centerFraction = [];
    return;
end

nFRAMES = length(coordData);

x = coordData(:, 1);
y = coordData(:, 2);

% Center boundaries based on the observed movement ranges.
xBorder = range(x) * BORDERLIMIT;
yBorder = range(y) * BORDERLIMIT;
leftBoundary = min(x) + xBorder;
rightBoundary = max(x) - xBorder;
topBoundary = min(y) + yBorder;
bottomBoundary = max(y) - yBorder;

% A frame is in the border region if it is outside any center boundary.
isBorderFrame = x < leftBoundary | x > rightBoundary | ...
                y < topBoundary | y > bottomBoundary;

borderFrames = find(isBorderFrame);

% Frames outside the border region are in the center.
centerFrames = setdiff(1:nFRAMES, borderFrames);

% Percentage of all frames spent in the center, rounded to a whole percent.
centerFraction = round((length(centerFrames) * 100) / nFRAMES);
