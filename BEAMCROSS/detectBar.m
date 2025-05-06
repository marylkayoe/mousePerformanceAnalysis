function [barTopYCoord, barWidth] = detectBar(barImage, mouseStartPosition, varargin)
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
%           'barTapeWidth' - Percentage of image width for bar tape width (default:2%).
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
addParameter(p, 'MAKEDEBUGPLOT', false, @(x) islogical(x)); % to show some extra visualization
addParameter(p, 'barTapeWidth', 2, @(x) isnumeric(x) && x > 0 && x <= 10);

parse(p, varargin{:});
MAKEDEBUGPLOT = p.Results.MAKEDEBUGPLOT;
barTapeWidth = p.Results.barTapeWidth;


% check that the image is not empty and has some size
if isempty(barImage) || isempty(mouseStartPosition)
    warning('Input image is empty or mouse start position is not defined.');
    barTopYCoord = [];
    barWidth = [];
end


% 1. Define the tape-mark-window size 
[imHeight, imWidth] = size(barImage);
tapeMarkWindowSize = round(imWidth * (barTapeWidth / 100));
MAXTAPEWIDTH = 0.1*imHeight; % maximum tape width (percentage of image height)

% Define horizontal regions in the image where we look for tape marks regions  - will be opposite to mouseStartPosition
if strcmp(mouseStartPosition, 'R')
    tapeMarkRegion = 1:tapeMarkWindowSize;
else
    tapeMarkRegion = imWidth-tapeMarkWindowSize+1:imWidth;
end

% calculate sum of rows in the tape mark region
tapeRegionSum = sum(barImage(:, tapeMarkRegion), 2);

% find the minimum value in the left and right regions
[~, tapeMinIndex] = min(tapeRegionSum);

% top of bar is the coordinate above the MinIdx at which the sum of the region is rapidly increasing
% bottom of bar is the coordinate below the MinIdx at which the sum of the region is rapidly increasing
% (background is white behind the tape mark)

% find top of the bar
aboveBarSum = tapeRegionSum(1:tapeMinIndex);
aboveBarSumDiff = diff(aboveBarSum);
%aboveBarSumDiff = medfilt1(aboveBarSumDiff, 5); % Apply median filtering
edgeThreshold = std(aboveBarSumDiff) * 2;

[~, barTopLoc, ~, ~] = findpeaks(-aboveBarSumDiff, 'MinPeakHeight', edgeThreshold);
if isempty(barTopLoc)
    warning('No peaks found in the top region, defaulting to fixed value (10 px above min).');
    barTopLoc = tapeMinIndex - floor(MAXTAPEWIDTH/2); % default to half of tape width 
else
    barTopLoc = barTopLoc(end); % adjust with respect to the middle of the bar
end
% find bottom of the bar; note that the bottom of the image is white, we need to look in the region below the that is not more than some % of the image height

cropBelowBarHeight = round(imHeight * 0.1);
belowBarSum = tapeRegionSum(tapeMinIndex+1:min(tapeMinIndex+cropBelowBarHeight, imHeight));
belowBarSumDiff = diff(belowBarSum);
%belowBarSumDiff = medfilt1(belowBarSumDiff, 5); % Apply median filtering
edgeThreshold = std(belowBarSumDiff) * 2;

% Identify bottom of the bar
[~, barBottomLoc, ~, ~] = findpeaks(belowBarSumDiff, 'MinPeakHeight', edgeThreshold);
if isempty(barBottomLoc)
    warning('No peaks found in the bottom left region, defaulting to fixed value (10 px below min).');
    barBottomLoc = tapeMinIndex + floor(MAXTAPEWIDTH/2); % default to 10 pixels below the min index
else

barBottomLoc = barBottomLoc(end) + tapeMinIndex; % adjust with respect to the middle of the bar
end

bufferSize = 2; % pixels
barTopYCoord = max(barTopLoc - bufferSize, 1);
barBottomYCoord = min(barBottomLoc + bufferSize, imHeight);

% calculate the bar width as the average of the two tape marks
barWidth = round((barBottomYCoord - barTopYCoord));

% Sanity check bar width
maxAllowableBarWidth = round(imHeight * 0.1); % e.g., no more than 10% of image height
if barWidth > maxAllowableBarWidth
    warning('Bar width (%d px) exceeds 10%% of image height. Defaulting to %d px.', barWidth, maxAllowableBarWidth);
    barWidth = maxAllowableBarWidth;
end


%% Debugging Plot
if MAKEDEBUGPLOT
    cropBarImage = barImage(:, tapeMarkRegion);
    figure; imshow(cropBarImage, []);
    hold on;

    plot([1, size(cropBarImage, 2)], [barTopYCoord, barTopYCoord], 'r', 'LineWidth', 2);
    % add line for bottom of bar
    plot([1, size(cropBarImage, 2)], [barBottomYCoord, barBottomYCoord], 'g', 'LineWidth', 2);
    title(['Detected Bar Position (based on tapes):', num2str(barTopYCoord)]);
    legend('Top of bar', 'Bottom of bar', 'Location', 'Best');
    
    hold off;

    drawnow;
end


end
