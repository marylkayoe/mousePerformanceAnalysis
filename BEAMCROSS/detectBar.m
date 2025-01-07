function [barYCoord, barWidth] = detectBar(barImage)
%  Locate the top edge of a (white) balance bar in an image.
%
%   [barYCoord, barWidth] = findBarYCoordInImage(barImage)
%   INPUT:
%       barImage - Grayscale (uint8 image of the scene
%                  containing a white bar plus two black camera rectangles.
%   OUTPUT:
%       barYCoord - The row index (1-based) of the bar’s top edge
%       barWidth  - The vertical thickness of the bar (pixels) (hardcoded)
%
%   ALGORITHM:
%     1) Determine the X-range of the cameras in the image by summing columns.
%     2) Crop to that horizontal range.
%     3) Use findCameraEdgeCoordsInImage(...) to remove top & bottom camera areas.
%     4) Threshold to find bright bar.
%     5) Use vertical projection to locate bottom edge of the bar, then
%        subtract a fixed bar thickness to get the top edge.

    % We'll define the bar width as 5% of total image height
    BARWIDTHPERC = 5;
    [imHeight, imWidth] = size(barImage);

    barWidth = round(imHeight * (BARWIDTHPERC / 100));
    %% 1) Find camera zone horizontally
    horizSum     = sum(barImage, 1);  % sum each column
    horizSumDiff = diff(horizSum);
    edgeThreshold = std(horizSumDiff);
    % Left camera edge => negative peak
    [~, locsLeft] = findpeaks(-horizSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(locsLeft)
        warning('No left camera edge found, defaulting to 1');
        camXleft = 1;
    else
        camXleft = locsLeft(1);
    end

    % Right camera edge => positive peak
    [~, locsRight] = findpeaks(horizSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(locsRight)
        warning('No right camera edge found, defaulting to imWidth');
        camXright = imWidth;
    else
        camXright = locsRight(end);
    end

    camRangeX = camXleft:camXright;
    cropBarImage = barImage(:, camRangeX);

    %% 2) Remove the top and bottom camera rectangles
    [topCameraEdgeY, bottomCameraEdgeY] = detectCameras(cropBarImage);
    topCameraEdgeY    = topCameraEdgeY + 5;  % buffer
    bottomCameraEdgeY = bottomCameraEdgeY - 5;
    cropBarImage      = cropBarImage(topCameraEdgeY:bottomCameraEdgeY, :);
    %% 3) Threshold to isolate bright bar
    numThresholds = 2;
    levels = multithresh(cropBarImage, numThresholds);
    segBarImage = imquantize(cropBarImage, levels);
    % The bar should be in the upper intensity category.

 %% 4) Find vertical position of the bar
    vertSum = sum(segBarImage, 2);      % sum each row 
    vertSumDiff = diff(vertSum);
    edgeThreshold = std(vertSumDiff)*3;

    % bottom of the bar => presumably a positive jump to lower intensities
    [~, locsBottom] = findpeaks(vertSumDiff, 'MinPeakHeight', edgeThreshold);
    if isempty(locsBottom)
        warning('No bar bottom found, defaulting to bottomCameraEdgeY');
        barYCoordBottom = bottomCameraEdgeY;
    else
        barYCoordBottom = locsBottom(end) + topCameraEdgeY;
    end

    % The top edge is bottom minus barWidth
    barYCoord = barYCoordBottom - barWidth;

end
