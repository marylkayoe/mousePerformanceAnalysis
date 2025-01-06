function [mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, meanPosturalHeight, mouseMaskMatrix, trackedVideo, croppedVideo] = BBtrackingMouse(croppedVideo, MOUSESIZETH, FRAMERATE)
% track the mouse in the video
% input: croppedVideo - video matrix with the mouse (uint8)
%        MOUSESIZETH - minimum size of the mouse in fraction of the image,
%                      used to filter out noise, default 15
% output: mouseCentroids - centroid positions of the mouse per frame

 if ~exist('MOUSESIZETH', 'var')
     MOUSESIZETH = 5;
 end
 if ~exist('FRAMERATE', 'var')
     FRAMERATE = 160;
 end
 

% get the size of the video
[imHeight, imWidth, nFrames] = size(croppedVideo);

frameArea = imHeight * imWidth;
minMouseArea = MOUSESIZETH/100 * frameArea;  % 5% of total pixel count


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


markerSize = 10;    % size of the tracking point to be added in video

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

    % add marker to indicate the centroid
    frameWithMarker = insertShape(ratioFrame, 'FilledCircle', ...
    [centroid(1), centroid(2), markerSize/2], 'Color', [1 1 1], 'Opacity', 1);
    % need to convert the frame back to gray from RGB
     ratioMatrix(:,:,frameIndex) = rgb2gray(frameWithMarker);

end
% 

 trackedVideo = ratioMatrix;

% check the period when mouse is seen, longest continuous non-NAN period
% is the period when the mouse is on the beam
% use morphological operations to find period of non-nan
mouseFoundFrames = ~isnan(mouseCentroids(:,1));
mouseFoundFrames = imclose(mouseFoundFrames, strel('disk', 5));
mouseFoundFrames = bwareaopen(mouseFoundFrames, 10);
mouseFoundPeriods = regionprops(mouseFoundFrames, 'Area', 'PixelIdxList');
[~, longestPeriodIndex] = max([mouseFoundPeriods.Area]);
longestPeriod = mouseFoundPeriods(longestPeriodIndex).PixelIdxList;

% crop out everything else than the period when mouse is in picture
mouseCentroids = mouseCentroids(longestPeriod, :);
 trackedVideo = trackedVideo(:, :, longestPeriod);
 mouseMaskMatrix = mouseMaskMatrix(:, :, longestPeriod);
 croppedVideo = croppedVideo(:, :, longestPeriod);

% calculate instantaneous speed of the mouse, using FRAMERATE
% calculate the distance between consecutive frames in X dimension only
forwardSpeeds = nan(length(mouseCentroids),1);
velWin = floor(FRAMERATE/10);
[frameDisplacements ] = pdist2(mouseCentroids(2:end,1), mouseCentroids(1:end-1,1), 'euclidean');
winDisplacements = diag(frameDisplacements, -velWin);

forwardSpeeds(1:length(winDisplacements)) = winDisplacements / (velWin / FRAMERATE);
meanSpeed = nanmean(forwardSpeeds);

% other measures
traverseDuration = length(forwardSpeeds) / FRAMERATE;
meanPosturalHeight = nanmean(mouseCentroids(:, 2));


end


