function mouseCentroids = BBtrackingMouse(croppedVideo, MOUSESIZETH)
% track the mouse in the video
% input: croppedVideo - video matrix with the mouse (uint8)
%        MOUSESIZETH - minimum size of the mouse in fraction of the image,
%                      used to filter out noise, default 15
% output: mouseCentroids - centroid positions of the mouse per frame

if nargin < 2
    MOUSESIZETH = 5;
end

% get the size of the video
[imHeight, imWidth, nFrames] = size(croppedVideo);

frameArea = imHeight * imWidth;
minMouseArea = MOUSESIZETH/100 * frameArea;  % 15% of total pixel count


% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = nan(nFrames, 2);
meanFrame = getMeanFrame(croppedVideo);
croppedVideoDouble = im2double(croppedVideo)+eps;
meanFrameD = im2double(meanFrame) + eps;
ratioMatrix = croppedVideoDouble ./ meanFrameD;
mouseMaskMatrix = ratioMatrix < 0.6;

% Cleanup
mouseMaskMatrix = imclose(mouseMaskMatrix, strel('disk', 3));
mouseMaskMatrix = bwareaopen(mouseMaskMatrix, 50);
 markerSize = 10;    % diameter in pixels

for frameIndex = 1:nFrames
    
    % Extract the mask for this frame
    maskFrame = mouseMaskMatrix(:,:,frameIndex);
    ratioFrame = ratioMatrix(:, :, frameIndex);

    % Find connected components and compute area + centroid
    props = regionprops(maskFrame, 'Area', 'Centroid');

    if isempty(props)
        % No mouse found in this frame?
  %      warning('Frame %d: no object detected. Storing NaNs.', frameIndex);
        continue;
    end

    % Filter out blobs smaller than the minArea
    largeBlobs = props([props.Area] >= minMouseArea);
    if isempty(largeBlobs)
        % All blobs are too small
      %  warning('Frame %d: no blob >= 15%% of frame. Storing NaNs.', frameIndex);
        continue;
    end
    % If there's more than one large blob, pick the largest
    [~, largestIndex] = max([largeBlobs.Area]);
    centroid = largeBlobs(largestIndex).Centroid;
    mouseCentroids(frameIndex, :) = centroid;

    frameWithMarker = insertShape(ratioFrame, 'FilledCircle', ...
    [centroid(1), centroid(2), markerSize/2], 'Color', [1 1 1], 'Opacity', 1);
     ratioMatrix(:,:,frameIndex) = rgb2gray(frameWithMarker);

end

displayBehaviorVideoMatrix(ratioMatrix);
title('Mouse tracking');





end


