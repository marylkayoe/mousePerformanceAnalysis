function [barTopYCoord, barWidth, tapeCenterCoord] = detectBar(barImage, varargin)
% Detect the top edge of the balance bar in an image.
%
%   [barYCoord, barWidth] = detectBar(barImage, mouseStartPosition, varargin)
%   INPUT:
%       barImage - Grayscale (uint8) image containing the balance bar and cameras.
%       'mouseStartPosition' L or R, to indicate the side of the bar where the mouse is at the start
%                          of the trial (default: 'L'). It is used to determine the
%                          position of the bar.
%       varargin - Optional parameters:
%           'MAKEDEBUGPLOT' - Enable debugging plots (default: false).
%           'barTapeWidth' - Percentage of width for bar tape width (default:2%).
%
%   OUTPUT:
%       barTopYCoord - The row index of the bar’s top edge.
%       barWidth  - Estimated thickness of the bar (pixels).
%

%   ALGORITHM:
%     1) Define the tape-mark-window size and the regions for both sides.
%     2) Calculate the sum of rows in the tape mark region.
%     3) Find the minimum value in the tape mark region. This is center of the bar.
%     4) Find the top of the bar as coordinate where the region is rapidly brightening.
%     5) Find the bottom of the bar as coordinate where the region is rapidly brightening.
%     6) the difference of the two coordinates is the bar width.

% NOTE: if the bar is not straight, the value of bar position will be accurate only for the
%     one end of the bar. If we could be sure that the beginning of the video there are always some
% frames without a mouse, we could use the average of the two ends of the bar, or calculate a linear
%     regression line to get the bar position.

% parse input arguments
p = inputParser;
addParameter(p, 'MAKEDEBUGPLOT', true, @(x) islogical(x)); % to show some extra visualization
addParameter(p, 'tapeWindowFraction', 0.05, @(x) isnumeric(x) && x > 0 && x <= 10);
addParameter(p, 'mouseStartPosition', '', @(x) ischar(x) && (isempty(x) || any(strcmp(x, {'L', 'R'}))));
addParameter(p, 'maxBarHeightFraction', 0.1, @(x) isnumeric(x) && x > 0 && x <= 1);

parse(p, varargin{:});
MAKEDEBUGPLOT = p.Results.MAKEDEBUGPLOT;
tapeWindowFraction = p.Results.tapeWindowFraction;
mouseStartPosition = p.Results.mouseStartPosition;
maxBarHeightFraction = p.Results.maxBarHeightFraction;


% check that the image is not empty and has some size
if isempty(barImage) 
    warning('Input image is empty or mouse start position is not defined.');
    barTopYCoord = [];
    barWidth = [];
    return;
end

% 0 crop 10 pixels from left and right edges to avoid edge effects
barImage = barImage(:, 11:end-10);


% 1. Define the tape-mark-window size
% this should be a small fraction of the image width but still contain the entire tape region
% default is 1/20 (given by parameter tapeWindowFraction)
[imHeight, imWidth] = size(barImage);
tapeMarkWindowSize = round(imWidth * tapeWindowFraction);

% Define horizontal regions in the image where we look for tape marks
% first horizontally: make a sum and find the positions of dark dips

barHorizontalSum = sum(barImage, 1);
barHorizontalDiff = diff(barHorizontalSum);
edgeThreshold = std(barHorizontalDiff) * 4; % threshold for edge detection

% sudden decrease in brightness (negative peak in diff) indicates left edge of tape mark
% sudden increase in brightness (positive peak in diff) indicates right edge of tape mark
% tape centers are between these edges

[~, leftEdgeLocs] = findpeaks(-barHorizontalDiff, "MinPeakHeight", edgeThreshold, "MinPeakDistance", tapeMarkWindowSize/2);
[~, rightEdgeLocs]  = findpeaks(barHorizontalDiff, "MinPeakHeight", edgeThreshold, "MinPeakDistance", tapeMarkWindowSize/2);

% if we find more or less than 2 right or left edges, we issue a warning and default to fixed positions 1:tapeMarkWindowSize and imWidth-tapeMarkWindowSize+1:imWidth
if length(leftEdgeLocs) < 2 || length(rightEdgeLocs) < 2
    warning('Could not find two left and right edges of tape marks, defaulting to fixed positions.');
    leftEdgeL = 1;
    rightEdgeL = tapeMarkWindowSize;
    leftEdgeR = imWidth - tapeMarkWindowSize + 1;
    rightEdgeR = imWidth;
else
    leftEdgeL = leftEdgeLocs(1);
    rightEdgeL = rightEdgeLocs(1);
    leftEdgeR = leftEdgeLocs(end);
    rightEdgeR = rightEdgeLocs(end);
end

% we crop the two bartip images so that they start 10 pixels before left edges and end 10 pixels after right edges
% this way we ensure that we capture the tape marks fully in the cropped images with minimal background

tapeRegionLeft = max(leftEdgeL - 10, 1):min(rightEdgeL + 10, imWidth);
tapeRegionRight = max(leftEdgeR - 10, 1):min(rightEdgeR + 10, imWidth);

% if mousestartposition was given, we use the old version of code here:
if ~isempty(mouseStartPosition)
    if strcmp(mouseStartPosition, 'R')
        tapeMarkRegion = tapeRegionLeft;
    else
        tapeMarkRegion = tapeRegionRight;
    end
    barTipImage = barImage(:, tapeRegionLeft);
    [barTopCoord, barBottomCoord, barWidth, tapeCenterIndex] = LF_detectBarEdges(barTipImage, 'edgeContrastThreshold', 1.5, 'edgeBufferSize', 2, 'maxBarHeightFraction', maxBarHeightFraction);
else
    % if no mousestartposition given
    barTipImageL = barImage(:, tapeRegionLeft);
    barTipImageR = barImage(:, tapeRegionRight);
    tapeMarkRegion = [tapeRegionLeft, tapeRegionRight];
end


%barTipImageL = barImage(:, 1:tapeMarkWindowSize); % crop to tape mark region on the LEFT
[barTopCoordL, barBottomCoordL, barWidthL, tapeCenterIndexL] = LF_detectBarEdges(barTipImageL, 'edgeContrastThreshold', 1.5, 'edgeBufferSize', 2, 'maxBarHeightFraction', maxBarHeightFraction);
%barTipImageR = barImage(:, imWidth-tapeMarkWindowSize+1:imWidth); % crop to tape mark region on the RIGHT
[barTopCoordR, barBottomCoordR, barWidthR, tapeCenterIndexR] = LF_detectBarEdges(barTipImageR, 'edgeContrastThreshold', 1.5, 'edgeBufferSize', 2, 'maxBarHeightFraction', maxBarHeightFraction);

% if no mouse start position was given, we use the average of the two sides; otherwise we use the side opposite to the mouse start position
if isempty(mouseStartPosition)
    barTopYCoord = floor((barTopCoordL + barTopCoordR) / 2);
    barBottomYCoord = floor((barBottomCoordR + barBottomCoordL)/2);
    tapeCenterCoord = floor((tapeCenterIndexR + tapeCenterIndexL)/2);
    barWidth = round((barWidthL + barWidthR) / 2);
elseif strcmp(mouseStartPosition, 'R')
    barTopYCoord = barTopCoordL;
    barBottomYCoord = barBottomCoordL;
    tapeCenterCoord = tapeCenterIndexL;
    barWidth = barWidthL;
else
    barTopYCoord = barTopCoordR;
    barBottomYCoord = barBottomCoordR;
    tapeCenterCoord = tapeCenterIndexR;
    barWidth = barWidthR;
end

%% Debugging Plot
if MAKEDEBUGPLOT
    cropBarImage = barImage(:, tapeMarkRegion);
    cropBarImage = barImage;
    figure; imshow(cropBarImage, []);
    hold on;

    plot([1, size(cropBarImage, 2)], [barTopYCoord, barTopYCoord], 'r', 'LineWidth', 1);
    % add line for bottom of bar
    plot([1, size(cropBarImage, 2)], [barBottomYCoord, barBottomYCoord], 'g', 'LineWidth', 1);
    plot([1, size(cropBarImage, 2)], [tapeCenterCoord, tapeCenterCoord], 'b', 'LineWidth', 1);
    title(['Detected Bar Position (based on tapes):', num2str(barTopYCoord)]);
    legend('Top of bar', 'Bottom of bar', 'Location', 'Best');

    hold off;

    drawnow;
end


end


function [barTopCoord, barBottomCoord, barWidth, tapeCenterIndex] = LF_detectBarEdges(barImage, varargin)
% helper function for finding the vertical position of the top and bottom edge of a bar
% in the image region barTipImage
% the background is white and the bar is rather bright; a black piece of tape is attached to indicate the bar position
% INPUT:
%   barTipImage - grayscale image region containing the bar tip with tape mark
% optional parameters:
% edgeContrastThreshold - threshold for edge detection (default: 2*std of diff)
% edgeBufferSize - buffer size in pixels to avoid edge effects (default: 2 pixels)
% maxBarHeight - maximum allowable bar height (default: 10% of image height)
% OUTPUT:
%   barTopCoord - row index of the top edge of the bar
%   barBottomLoc - row index of the bottom edge of the bar
% parse input arguments
p = inputParser;
addParameter(p, 'edgeContrastThreshold', 2, @(x) isnumeric(x) && x > 0);
addParameter(p, 'edgeBufferSize', 2, @(x) isnumeric(x) && x >= 0);
addParameter(p, 'maxBarHeightFraction', 0.1, @(x) isnumeric(x) && x > 0 && x <= 1);

parse(p, varargin{:});

edgeContrastThreshold = p.Results.edgeContrastThreshold;
edgeBufferSize = p.Results.edgeBufferSize;
maxBarHeightFraction = p.Results.maxBarHeightFraction;

% 1. Define the tape-mark-window size
[imHeight, imWidth] = size(barImage);
MAXTAPEWIDTH = round(imHeight * maxBarHeightFraction); % maximum tape width (percentage of image height)


% calculate sum of rows in the tape mark region
% the top edge will be seen as sudden decrease in brightness (negative peak in diff)

tapeRegionSum = sum(barImage, 2);

% find the minimum value - this is maybe the midpoint of the bar
[~, tapeCenterIndex] = min(tapeRegionSum);

tapeRegionDiff = diff(tapeRegionSum);
edgeThreshold = std(tapeRegionDiff)* edgeContrastThreshold;

% new idea: tape is the region where absolute difference is high
absTapeRegionDiff = abs(tapeRegionDiff);
% let's smooth it a bit
smoothedAbsDiff = movmean(absTapeRegionDiff, 5);
% find region where smoothed abs diff is above threshold
candidateRegions = smoothedAbsDiff > std(smoothedAbsDiff);
barTopLoc = find(candidateRegions, 1, 'first');
barBottomLoc = find(candidateRegions, 1, "last");

% check that we found valid positions
if isempty(barTopLoc) || isempty(barBottomLoc)
    warning('Could not detect bar edges based on tape mark. Setting to default values.');
    barTopCoord = tapeCenterIndex - round(MAXTAPEWIDTH / 2);;
    barBottomCoord = tapeCenterIndex + round(MAXTAPEWIDTH / 2);;
    barWidth = barBottomCoord - barTopCoord;
    return;
end

% make sure the coordinates are within image bounds

barTopCoord = max(barTopLoc, 1);
barBottomCoord = min(barBottomLoc, imHeight);
barWidth = barBottomCoord - barTopCoord;
if barWidth > MAXTAPEWIDTH
    warning('Detected bar width (%d px) exceeds maximum allowable width (%d px). Better check the images!', barWidth, MAXTAPEWIDTH);
end

end