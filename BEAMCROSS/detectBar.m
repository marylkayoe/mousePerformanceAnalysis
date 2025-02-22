function [barYCoord, barWidth] = detectBar(barImage)
    % Detect the top edge of the balance bar in an image.
    %
    %   [barYCoord, barWidth] = detectBar(barImage)
    %   INPUT:
    %       barImage - Grayscale (uint8) image containing the balance bar and cameras.
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

    MAKEDEBUGPLOT = 1; % Enable debugging plots
    
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
    
    %% Debugging Plot
    if MAKEDEBUGPLOT
        figure; imshow(cropBarImage, []);
        hold on;
        plot([1, size(cropBarImage, 2)], [barYCoord-topCameraEdgeY, barYCoord-topCameraEdgeY], 'r', 'LineWidth', 2);
        hold off;
        title(['Detected Bar TOP Position:', num2str(barYCoord)]);
        drawnow;
    end
    
    end
    