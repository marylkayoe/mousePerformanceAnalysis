function [topCameraEdgeY, bottomCameraEdgeY] = detectCameras(meanImage)
    % Locate top & bottom camera edges (vertical coordinates) using two detection methods.
    %
    %   [topCameraEdgeY, bottomCameraEdgeY] = detectCameras(meanImage)
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
    %     1) Primary Method: Detect black camera rectangles using adaptive thresholding
    %        and morphological processing. Extract bounding boxes with `regionprops`.
    %     2) If exactly two rectangles are not found, fallback to an edge-detection
    %        method by analyzing vertical intensity profiles.
    
    % First, attempt detection using morphology-based approach
    bw = imbinarize(meanImage, 'adaptive', 'ForegroundPolarity', 'dark');
    bw = imclose(bw, strel('rectangle', [5,5])); % Fill small gaps
    bw = imopen(bw, strel('rectangle', [3,3]));  % Remove small noise
    
    % Extract object properties from binary image
    stats = regionprops(~bw, 'BoundingBox', 'Area', 'Extent');
    validRects = [];
    minArea = 0.005 * numel(meanImage); % Set dynamically as 0.5% of image size
    
    % Identify valid rectangular regions based on size and shape constraints
    for k = 1:length(stats)
        bb = stats(k).BoundingBox;
        aspectRatio = bb(3) / bb(4); % Ratio of width to height
        extent = stats(k).Area / (bb(3) * bb(4)); % How much the bounding box is filled
        
        % Check conditions for valid rectangles
        if stats(k).Area > minArea && extent > 0.8 && aspectRatio > 0.3 && aspectRatio < 2.5
            validRects = [validRects; bb];  % Store detected rectangles
        end
    end
    
    % Ensure valid rectangles were detected before sorting
    nRectangles = size(validRects, 1);
    if nRectangles == 2
        % Round and sort detected rectangles by their vertical position
        validRects = round(validRects);
        validRects = sortrows(validRects, 2); % Sort by Y position
        
        % Extract vertical positions
        topCameraEdgeY = validRects(1, 2) + validRects(1, 4); % Bottom of top camera
        bottomCameraEdgeY = validRects(2, 2); % Top of bottom camera
        return;
    end
    
    % If detection failed, proceed with multi-threshold and edge-based approach
    warning('regionProps camera detection failed, proceeding with edge detection.');
    
    % Segment the mean image into 3 levels using multi-thresholding
    levels = multithresh(meanImage, 2);
    segMeanFrame = imquantize(meanImage, levels);
    % Cameras should appear as a distinct (lowest) level if they’re black.
    
    %% --- Horizontal analysis ---------------------------------------
    % Sum intensity along columns to detect left and right boundaries
    horizontalProfile = sum(segMeanFrame, 1);
    horizontalProfileDiff = diff(horizontalProfile);
    edgeDetectThreshold = std(horizontalProfileDiff) * 2;
    
% Identify right boundary of camera zone
[~, locs, ~, ~] = findpeaks(horizontalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
if isempty(locs)
    camRightCoord = length(horizontalProfileDiff);
else
    camRightCoord = locs(end);
end

    
% Identify left boundary of camera zone
[~, locs, ~, ~] = findpeaks(-horizontalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
if isempty(locs)
    camLeftCoord = 1;
else
    camLeftCoord = locs(1);
end

    % Define camera region in X-range
    camRangeX = camLeftCoord:camRightCoord;
    
    % Crop image to the detected camera region
    segMeanFrame = segMeanFrame(:, camRangeX);
    
    %% --- Vertical analysis -----------------------------------------
    % Sum intensity along rows to detect top and bottom edges
    verticalProfile = sum(segMeanFrame, 2);
    verticalProfileDiff = medfilt1(diff(verticalProfile), 5); % Apply median filtering
    edgeDetectThreshold = std(verticalProfileDiff) * 3;
    
    % Identify bottom of the top camera
    [~, locs, ~, ~] = findpeaks(verticalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
    if isempty(locs)
        % define fallback value
        topCameraEdgeY = 1;
    else

    topCameraEdgeY = locs(1);
    end
    
    % Identify top of the bottom camera
    [~, locs, ~, ~] = findpeaks(-verticalProfileDiff, 'MinPeakHeight', edgeDetectThreshold);
    if isempty (locs)
  
        bottomCameraEdgeY = length(verticalProfileDiff);
        
    else

        bottomCameraEdgeY = locs(end);
    
    end
    end
    