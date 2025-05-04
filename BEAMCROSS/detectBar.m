function [barTopYCoord, barWidth] = detectBar(barImage, mouseStartPosition, varargin)
% Detect the top edge of the balance bar in an image.
%
%   [barYCoord, barWidth] = detectBar(barImage)
%   INPUT:
%       barImage - Grayscale (uint8) image containing the balance bar and cameras.
%       'mouseStartPosition' L or R, to indicate the side of the bar where the mouse is at the start
%                          of the trial (default: 'L'). It is used to determine the
%                          position of the bar.
%       varargin - Optional parameters:
%           'MAKEDEBUGPLOT' - Enable debugging plots (default: false).
%           'barTapeWidth' - Percentage of image width for bar tape width (default:3%).
%
%   OUTPUT:
%       barYCoord - The row index of the bar’s top edge.
%       barWidth  - Estimated thickness of the bar (pixels).
%

%   ALGORITHM:
%     1) Primary Method: Identify the horizontal range of the camera zone and crop the image.
%     2) Remove detected camera rectangles to focus on the bar.
%     3) Use adaptive thresholding to extract bright structures.
%     4) Identify the top-most horizontal structure spanning most of the width.
%     5) If the structure is not found, default to an estimated position based on changes in image brightness.

%

% parse input arguments
p = inputParser;
addParameter(p, 'MAKEDEBUGPLOT', false, @(x) islogical(x));
%addParameter(p, 'USENEWVER', true, @(x) islogical(x));
addParameter(p, 'barTapeWidth', 2, @(x) isnumeric(x) && x > 0 && x <= 10);

parse(p, varargin{:});
MAKEDEBUGPLOT = p.Results.MAKEDEBUGPLOT;
barTapeWidth = p.Results.barTapeWidth;



% in this version we detect the bar using a different method, based on the position of black
% tape marks at the beginning and end of bar. The tape marks are expected to be less than 5%
% of the image width.
% Logic is as follows:
% - defined windows at the beginning and end of the image where the tape marks are expected to be
% find peak of low intensity (should be center of black tape marks)
% find the top and bottom of the low intensity region, which should be the top and bottom of the bar
% also define the bar width as the width of the tape mark
% do this for both sides of the image and take the average
% of the two
% - if no tape marks are found, use the old method to detect the bar
% note: this method needs to receive the image without cropping the tape marks!

% 1. Define the tape-mark-window size and the regions for both sides

% check that the image is not empty and has some size
if isempty(barImage) || isempty(mouseStartPosition)
    warning('Input image is empty or mouse start position is not defined.');
    barTopYCoord = [];
    barWidth = [];
end

[imHeight, imWidth] = size(barImage);
tapeMarkWindowSize = round(imWidth * (barTapeWidth / 100));

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
    barTopLoc = tapeMinIndex - 10; % default to 10 pixels above the min index
end
% find bottom of the bar; note that the bottom of the image is white, we need to look in the region below the that is not more than 10% of the image height
cropBelowBarHeight = round(imHeight * 0.1);
belowBarSum = tapeRegionSum(tapeMinIndex+1:min(tapeMinIndex+cropBelowBarHeight, imHeight));
belowBarSumDiff = diff(belowBarSum);
%belowBarSumDiff = medfilt1(belowBarSumDiff, 5); % Apply median filtering
edgeThreshold = std(belowBarSumDiff) * 2;

% Identify bottom of the bar
[~, barBottomLoc, ~, ~] = findpeaks(belowBarSumDiff, 'MinPeakHeight', edgeThreshold);
barBottomLoc = barBottomLoc + tapeMinIndex;
if isempty(barBottomLoc)

    warning('No peaks found in the bottom left region, defaulting to fixed value (10 px below min).');
    barBottomLoc = tapeMinIndex + 10; % default to 10 pixels below the min index
end

% calculate averages for the top and bottom of the bar
barTopYCoord = barTopLoc(1);
barBottomYCoord = barBottomLoc(end);
% add a buffer to the top and bottom of the bar
barBottomYCoord = barBottomYCoord + 2; % add 2 pixels
barTopYCoord = barTopYCoord - 2; % subtract 2 pixels

% calculate the bar width as the average of the two tape marks
barWidth = round((barBottomYCoord - barTopYCoord));
% check that the bar width is not more than 10% of the image height
if barWidth > imHeight * 0.1
    warning('Bar width is too large, defaulting to 20 px.');
    barWidth = 20; % default to 20 pixels
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
