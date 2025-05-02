function [barYCoord, barWidth] = detectBar(barImage, mouseStartPosition, varargin)
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
%           'USENEWVER' - Use the new detection method (default: true).
%           'barTapeWidth' - Percentage of image width for bar tape width (default: 5%).
%
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
addParameter(p, 'USENEWVER', true, @(x) islogical(x));
addParameter(p, 'barTapeWidth', 3, @(x) isnumeric(x) && x > 0 && x <= 10);

parse(p, varargin{:});
MAKEDEBUGPLOT = p.Results.MAKEDEBUGPLOT;
USENEWVER = p.Results.USENEWVER;
barTapeWidth = p.Results.barTapeWidth;


if USENEWVER
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

    [imHeight, imWidth] = size(barImage);
    tapeMarkWindowSize = round(imWidth * (barTapeWidth / 100));

    % Define  tape mark regions (horizontal) - will be opposite to mouseStartPosition
    if strcmp(mouseStartPosition, 'R')
        tapeMarkRegion = 1:tapeMarkWindowSize;
    else
        tapeMarkRegion = imWidth-tapeMarkWindowSize+1:imWidth;
    end


    % calculate sum of rows in the tape mark region
    tapeRegionSum = sum(barImage(:, tapeMarkRegion), 2);

    % find the minimum value in the left and right regions
    [tapeIntensityValue, tapeMinIndex] = min(tapeRegionSum);

    %tapeIntensityThreshold = 100 * tapeMarkWindowSize; not needed


    % top of bar is the coordinate above the MinIdx at which the sum of the region is rapidly increasing
    % bottom of bar is the coordinate below the MinIdx at which the sum of the region is rapidly increasing
    % (background is white behind the tape mark)

    % find top of the bar
    aboveBarSum = tapeRegionSum(1:tapeMinIndex);
    aboveBarSumDiff = diff(aboveBarSum);
    aboveBarSumDiff = medfilt1(aboveBarSumDiff, 5); % Apply median filtering
    edgeThreshold = std(aboveBarSumDiff) * 2;

    % Identify top of the bar
    [~, barTopLoc, ~, ~] = findpeaks(-aboveBarSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(barTopLoc)
        USENEWVER = false; % if no peaks are found, use the old method
        warning('No peaks found in the top left region, using old method to detect bar.');
    end
    % find bottom of the bar; note that the bottom of the image is white, we need to look in the region below the that is not more than 10% of the image height
    cropBelowBarHeight = round(imHeight * 0.1);
    belowBarSum = tapeRegionSum(tapeMinIndex+1:min(tapeMinIndex+cropBelowBarHeight, imHeight));
    belowBarSumDiff = diff(belowBarSum);
    belowBarSumDiff = medfilt1(belowBarSumDiff, 5); % Apply median filtering
    edgeThreshold = std(belowBarSumDiff) * 2;

    % Identify bottom of the bar
    [~, barBottomLoc, ~, ~] = findpeaks(belowBarSumDiff, 'MinPeakHeight', edgeThreshold);
    barBottomLoc = barBottomLoc + tapeMinIndex;
    if isempty(barBottomLoc)
        USENEWVER = false; % if no peaks are found, use the old method
        warning('No peaks found in the bottom left region, using old method to detect bar.');
    end

    % calculate averages for the top and bottom of the bar
    barTopYCoord = barTopLoc(end);

    barBottomYCoord = barBottomLoc(end);
    % add a buffer to the top and bottom of the bar
    barBottomYCoord = barBottomYCoord + 5; % add 5 pixels
    barTopYCoord = barTopYCoord - 5; % subtract 5 pixels

    % calculate the bar width as the average of the two tape marks
    barWidth = round((barBottomYCoord - barTopYCoord));
    % check that the bar width is not more than 10% of the image height
    if barWidth > imHeight * 0.1
        USENEWVER = false; % if the bar width is too large, use the old method
        warning('Bar width is too large, using old method to detect bar.');
    end



    cropBarImage = barImage(:, tapeMarkRegion);
end


if ~USENEWVER
    % Define bar width estimate as 5% of total image height
    BARWIDTHPERC = 5;
    [imHeight, imWidth] = size(barImage);
    barWidth = round(imHeight * (BARWIDTHPERC / 100));

    %% Step 1: Identify Camera Zone in X-direction
    horizSum = sum(barImage, 1); % Sum along columns
    horizSumDiff = diff(horizSum);
    edgeThreshold = std(horizSumDiff);

    % Find left camera edge (negative peak)
    [~, locsLeft] = findpeaks(-horizSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(locsLeft)
        camXleft = 1;
    else
        camXleft = locsLeft(1);
    end

    % Find right camera edge (positive peak)
    [~, locsRight] = findpeaks(horizSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(locsRight)
        camXright = imWidth;
    else
        camXright = locsRight(end);
    end

    camRangeX = camXleft:camXright;
    cropBarImage = barImage(:, camRangeX);

    %% Step 2: Remove Camera Rectangles
    [topCameraEdgeY, bottomCameraEdgeY] = detectCameras(barImage);
    topCameraEdgeY = topCameraEdgeY + 5;  % Add buffer
    bottomCameraEdgeY = bottomCameraEdgeY - 5; % Add buffer
    cropBarImage = cropBarImage(topCameraEdgeY:bottomCameraEdgeY, :);

    %% Step 3: Extract Bright Structures Using Thresholding
    bw = imbinarize(cropBarImage, 'adaptive', 'ForegroundPolarity', 'bright');
    bw = imclose(bw, strel('line', 10, 0)); % Connect broken segments
    bw = imfill(bw, 'holes');

    %% Step 4: Find Topmost Horizontal Structure Spanning the Width
    regionStats = regionprops(bw, 'BoundingBox', 'Area');
    validBars = [];

    for k = 1:length(regionStats)
        bb = regionStats(k).BoundingBox;
        aspectRatio = bb(3) / bb(4); % Width/Height ratio

        if aspectRatio > 10 % Ensure the shape is long and horizontal
            validBars = [validBars; bb];
        end
    end

    % Select the topmost detected bar
    if isempty(validBars)
        warning('No valid bar detected, defaulting to estimated position.');
        barYCoord = topCameraEdgeY + round((bottomCameraEdgeY - topCameraEdgeY) / 2);
    else
        validBars = sortrows(validBars, 2); % Sort by Y position
        barYCoord = round(validBars(1, 2)) + topCameraEdgeY; % Select topmost structure
    end

end % USEOLDVERSION

%% Debugging Plot
if MAKEDEBUGPLOT
    figure; imshow(cropBarImage, []);
    hold on;
    if USENEWVER
        plot([1, size(cropBarImage, 2)], [barTopYCoord, barTopYCoord], 'r', 'LineWidth', 2);
        title(['Detected Bar TOP Position (based on tapes):', num2str(barTopYCoord)]);
        barYCoord = barTopYCoord;
    else
        plot([1, size(cropBarImage, 2)], [barYCoord-topCameraEdgeY, barYCoord-topCameraEdgeY], 'r', 'LineWidth', 2);
        title(['Detected Bar TOP Position (old method):', num2str(barYCoord)]);
    end
    hold off;

    drawnow;
end


end
