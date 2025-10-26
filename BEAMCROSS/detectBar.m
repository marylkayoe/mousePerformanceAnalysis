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


% 1. Define the tape-mark-window size
% this should be a small fraction of the image width but still contain the entire tape region
% default is 1/20 (given by parameter tapeWindowFraction)
[imHeight, imWidth] = size(barImage);
tapeMarkWindowSize = round(imWidth * tapeWindowFraction);

% Define horizontal regions in the image where we look for tape marks regions  - will be opposite to mouseStartPosition
if strcmp(mouseStartPosition, 'R')
    tapeMarkRegion = 10:tapeMarkWindowSize;
else
    tapeMarkRegion = imWidth-tapeMarkWindowSize+1:imWidth-10;
end

barTipImageL = barImage(:, 1:tapeMarkWindowSize); % crop to tape mark region on the LEFT
[barTopCoordL, barBottomCoordL, barWidthL, tapeCenterIndexL] = LF_detectBarEdges(barTipImageL, 'edgeContrastThreshold', 1.5, 'edgeBufferSize', 2, 'maxBarHeightFraction', maxBarHeightFraction);
barTipImageR = barImage(:, imWidth-tapeMarkWindowSize+1:imWidth); % crop to tape mark region on the RIGHT
[barTopCoordR, barBottomCoordR, barWidthR, tapeCenterIndexR] = LF_detectBarEdges(barTipImageR, 'edgeContrastThreshold', 2, 'edgeBufferSize', 2, 'maxBarHeightFraction', maxBarHeightFraction);

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

[~, locs, ~, ~] = findpeaks(-tapeRegionDiff, 'MinPeakHeight', edgeThreshold);

% if we found no peaks or less than 2 peaks:
if isempty(locs) || length(locs) < 2
    warning('No peaks found in the top region, defaulting to fixed value (10 px above min).');
    barTopLoc = tapeCenterIndex - floor(MAXTAPEWIDTH/2); % default to half of tape width
    barBottomLoc = tapeCenterIndex + floor(MAXTAPEWIDTH/2); % default to 10 pixels below the min index
else
    % we should at least have two peaks, first is top of bar, second is bottom of bar
    barTopLoc = locs(1);
    barBottomLoc = locs(end);
    % adjusting since the bottom peak is slightly shifted due to diff operation
    barBottomLoc = barBottomLoc + edgeBufferSize;
end

% make sure the coordinates are within image bounds

barTopCoord = max(barTopLoc, 1);
barBottomCoord = min(barBottomLoc, imHeight);
barWidth = barBottomCoord - barTopCoord;
if barWidth > MAXTAPEWIDTH
    warning('Detected bar width (%d px) exceeds maximum allowable width (%d px). Better check the images!', barWidth, MAXTAPEWIDTH);
end

end