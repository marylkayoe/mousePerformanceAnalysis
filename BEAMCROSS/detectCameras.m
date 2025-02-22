function [topCameraEdgeY, bottomCameraEdgeY] = detectCameras(meanImage)
% Locate top & bottom camera edges (vertical coords).
%
%   [topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(meanImage)
%   INPUT:
%       meanImage - Grayscale image (uint8) containing two black camera
%                   rectangles, one around the middle and one near the bottom.
%                   The bar is in between these.
%
%   OUTPUT:
%       topCameraEdgeY    - The row index of the bottom edge of the top camera
%       bottomCameraEdgeY - The row index of the top edge of the bottom camera
%
%   ALGORITHM:
%     1) Segment the image using two thresholds (3-level quantization).
%     2) Identify horizontal range of camera zone by summing columns and
%        detecting edges with findpeaks.
%     3) Crop to that horizontal zone, then sum rows and detect vertical
%        peaks to find top/bottom camera edges.

% 1) Segment the mean image into 3 levels
levels = multithresh(meanImage, 2);
segMeanFrame = imquantize(meanImage, levels);
% Cameras should appear as a distinct (lowest) level if they’re black.

bw = imbinarize(meanImage, 'adaptive', 'ForegroundPolarity', 'dark');
bw = imclose(bw, strel('rectangle', [5,5])); % Fill small gaps
bw = imopen(bw, strel('rectangle', [3,3]));  % Remove small noise


%% --- Horizontal analysis ---------------------------------------
% sum across columns -> horizontalProfile
horizontalProfile = sum(segMeanFrame, 1);
horizontalProfileDiff = diff(horizontalProfile);
edgeDetectThreshold = std(horizontalProfileDiff) * 2;

% right end of "camera zone":
[~, locs, ~, ~] = findpeaks(horizontalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
if isempty(locs) %
    camRightCoord = length(horizontalProfileDiff);
else
    camRightCoord = locs(end);
end

% left end of "camera zone"
[~, locs, ~, ~] = findpeaks(-horizontalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
if isempty(locs)
    camLeftCoord = 1;
else
    camLeftCoord = locs(1);
end

camRangeX = camLeftCoord:camRightCoord;

%crop the image to the horizontal range of cameras
segMeanFrame = segMeanFrame(:, camRangeX);

bw = bw(:, camRangeX);


stats = regionprops(~bw, 'BoundingBox', 'Area', 'Extent');
validRects = [];
minArea = 1000; % NEED TO CALCULATE THIS instead of fixed value
for k = 1:length(stats)
    bb = stats(k).BoundingBox;
    extent = stats(k).Area / (bb(3) * bb(4));

    if stats(k).Area > minArea && extent > 0.8
        validRects = [validRects; bb];  % Store detected rectangles
    end
end

validRects = round(validRects);

nRectangles = height(validRects);

if nRectangles ~= 2
    warning('regionProps camera detection failed, proceeding with edges');
    %% --- Vertical analysis -----------------------------------------
    verticalProfile = sum(segMeanFrame, 2);
    verticalProfileDiff = diff(verticalProfile);
    edgeDetectThreshold = std(verticalProfileDiff) * 3;

    % find the bottom position of the top camera rectangle in Y
    [pks, locs, widths, p] = findpeaks(verticalProfileDiff, 'MinPeakHeight',edgeDetectThreshold);
    % top camera bottom edge
    topCameraEdgeY = locs(1);

    [pks, locs, widths, p] = findpeaks(-verticalProfileDiff, 'MinPeakHeight',edgeDetectThreshold);
    % bottom camera top edge
    bottomCameraEdgeY = locs(end);

else
    topCameraEdgeY = validRects(1, 2) + validRects(1, 4);

    bottomCameraEdgeY = validRects(2, 2);
end



end

