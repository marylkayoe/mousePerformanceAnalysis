function [mouseCentroids, instForwardSpeed, meanSpeed, traverseDuration, stoppingStartStops, ...
stoppingFrames, meanSpeedLoco, stdSpeedLoco, mouseMaskMatrix, trackedVideo, croppedVideo] = ...
trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, USEMORPHOCLEAN, mouseContrastThreshold, FRAMERATE)
% TRACKMOUSEONBEAM  Detect and track the mouse in a cropped grayscale video of a balance beam.
%
%   [mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, meanPosturalHeight, ...
%    mouseMaskMatrix, trackedVideo, croppedVideo] = trackMouseOnBeam(croppedVideo, MOUSESIZETH, FRAMERATE)
%
%   This function identifies the mouse silhouette in each frame of a "croppedVideo"
%   (where the beam and mouse are visible), calculates the mouse's centroid over time,
%   and computes basic speed and duration statistics for the crossing.
%
%   INPUTS:
%       croppedVideo : A 3D video array of size (height x width x nFrames), uint8.
%                     Contains the portion of the original video where the mouse is.
%       MOUSESIZETH  : (Optional) Minimum fraction (0..100) of the total frame area
%                      that a connected blob must have to be considered the mouse.
%                      For example, 5 => at least 5% of the frame. Default is 5.
%       FRAMERATE    : (Optional) Video frame rate (frames/sec). Default is 160.
%                      Used for converting frame-based displacements to speeds.
%       LOCOTHRESHOLD: (Optional) Speed threshold (pixels/sec) below which the mouse
%                      is considered to be "stopped". Default is 100.
%       USEMORPHOCLEAN: (Optional) Logical flag to apply morphological cleanup
%                      to the binary mask. Default is false. Should not be needed.
%       mouseContrastThreshold: (Optional) Threshold for the ratio image to
%                      identify the mouse. Default is 0.6.
%
%   OUTPUTS:
%       mouseCentroids   : (nFrames x 2) array of mouse [x, y] centroids (in pixels).
%                          Frames where the mouse was not found are NaN.
%       forwardSpeeds    : (nFrames x 1) instantaneous forward speeds (pixels/sec).
%       meanSpeed        : (scalar) average speed (pixels/sec) across the detected frames.
%       traverseDuration : (scalar) time in seconds from the first to last frame
%                          where the mouse is detected continuously.
%       mouseMaskMatrix  : (height x width x nFrames) logical array marking where the
%                          mouse is detected in each frame.
%       mouseEnhancedFrames     : (height x width x nFrames) double array, where each frame
%                          has been “ratio-ed” to the mean frame and annotated with
%                          a small white dot at the centroid location. Useful for
%                          quick visualization.
%       croppedVideo     : (height x width x nFrames) subset of the input video,
%                          further trimmed to only the frames during which the mouse
%                          was actually present. (Frames before/after are removed.)
%       trackedVideo     : (height x width x nFrames) enhanced video with background 
%                           removed  and the centroid marker added.
%
%   ALGORITHM OVERVIEW:
%       1) Compute a "mean frame" from the input video.
%       2) Compute a "ratio image" for each frame, where each pixel is the ratio
%          of the pixel value in that frame to the mean frame. This enhances the
%          mouse silhouette as a darker region.
%       3) Threshold the ratio image to create a binary mask of the mouse.
%       4) Use regionprops to find connected components in the mask, and
%          identify the largest blob as the mouse.
%       5) Calculate the centroid of the largest blob and store it in mouseCentroids.
%       6) Calculate the instantaneous forward speed of the mouse based on
%          the displacement of the centroid over time (in horizontal direction only).
%       7) Identify periods of stopping based on the forward speed.
%       8) Return the mouse centroids, forward speeds, mean speed, and
%          traverse duration, along with the cropped video and mouse mask matrix.

%
%   EXAMPLE:
%       % Suppose we have a cropped video and we know the mouse is at least 5% of the frame
%    %       % and the frame rate is 160 fps.
%       [mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, ...
%        mouseMaskMatrix, trackedVideo, croppedVideo] = ...
%           trackMouseOnBeam(croppedVideo, 5, 100, 160);

%
%       implay(uint8(tVid)); % visualize the trackedVideo frames
%
%   DEPENDENCIES:
%       getMeanFrame, regionprops, insertShape, bwareaopen, imclose, etc.
%
% -------------------------------------------------------------------------

%% Default Parameters
if ~exist('MOUSESIZETH', 'var')
    MOUSESIZETH = 5;   % default: 5% of frame
end
if ~exist('LOCOTHRESHOLD', 'var')
    LOCOTHRESHOLD = 100;   % default: 100 pixels/sec
end
if ~exist('FRAMERATE', 'var')
    FRAMERATE = 160;   % default: 160 fps
end
if ~exist('USEMORPHOCLEAN', 'var')
    USEMORPHOCLEAN = false;   % default: no morphological cleanup
end
if ~exist('mouseContrastThreshold', 'var')
    mouseContrastThreshold = 0.6;   % default: no morphological cleanup
end

% Basic video info
[imHeight, imWidth, nFrames] = size(croppedVideo);
frameArea = imHeight * imWidth;
minMouseArea = (MOUSESIZETH / 100) * frameArea;  % e.g. 5% => min area threshold
markerSize = 10;    % radius of the centroid marker in video(in pixels)

%% Preallocate output arrays
mouseCentroids = nan(nFrames, 2);
stoppingStartStops = cell(0);

% 1) Compute ratio image to enhance mouse as darker region
meanFrame = getMeanFrame(croppedVideo);
croppedVideoDouble = im2double(croppedVideo) + eps;  % small eps to avoid /0
meanFrameD         = im2double(meanFrame) + eps;
mouseEnhancedFrames        = croppedVideoDouble ./ meanFrameD;

% 2) Threshold ratio < mouseContrastThreshold => binary mask. Then morphological cleanup
% change the values depending on how big and clear the mouse is
mouseMaskMatrix = (mouseEnhancedFrames < mouseContrastThreshold);
if USEMORPHOCLEAN
    mouseMaskMatrix = imclose(mouseMaskMatrix, strel('disk', 3)); % close small gaps
    mouseMaskMatrix = bwareaopen(mouseMaskMatrix, 50); % remove very small noise
end

disp('Tracking mouse position...');

[xGrid, yGrid] = meshgrid(1:imWidth, 1:imHeight); % for centroid marker calculation

%% Loop through frames: find largest blob & mark its centroid
for frameIndex = 1:nFrames
    % binary frame for mouse detection
    maskFrame  = mouseMaskMatrix(:,:,frameIndex);
    % frame to be used in visualization with centroid indicated
    enhancedFrame = mouseEnhancedFrames(:,:,frameIndex);

    % Find all connected components in the mask
    % regionprops() returns a structure array with properties of each blob
    % 'Area' is the number of pixels in the blob, 'Centroid' is its center
    props = regionprops(maskFrame, 'Area', 'Centroid');
    if isempty(props)
        % No blobs => skip (NaNs remain in mouseCentroids).
        continue;
    end

    % Discard blobs smaller than minMouseArea
    largeBlobs = props([props.Area] >= minMouseArea);
    if isempty(largeBlobs)
        continue;
    end

    % Pick the largest blob and identify its centroid as mouse position
    [~, largestIndex] = max([largeBlobs.Area]);
    thisFrameCentroid = largeBlobs(largestIndex).Centroid;
    mouseCentroids(frameIndex, :) = thisFrameCentroid;

    % Change pixels denoting centroid of the largest blob to white
    markerX = round(thisFrameCentroid(1));
    markerY = round(thisFrameCentroid(2));

    % xgrid is meshgrid to allow calculation of a circle
    % calculate which pixels are within the circle
    circleMask = (xGrid - markerX).^2 + (yGrid - markerY).^2 <= (markerSize/2)^2;
    % set the pixels in the enhanced frame to white
    enhancedFrame(circleMask) = 1;

    % replace the frame in mouseEnhancedFrames with the enhanced frame
    % for visualization
    mouseEnhancedFrames(:,:,frameIndex) = enhancedFrame;
end

%% Identify the longest continuous segment of frames with a valid centroid
mouseFoundFrames = ~isnan(mouseCentroids(:,1));
% Morphological closing to fill gaps (discontinuities) smaller than ~5 frames
mouseFoundFrames = imclose(mouseFoundFrames, strel('disk', 5));
% Remove isolated segments of mouse detection shorter than 10 frames
mouseFoundFrames = bwareaopen(mouseFoundFrames, 10);

mouseFoundPeriods = regionprops(mouseFoundFrames, 'Area', 'PixelIdxList');

if isempty(mouseFoundPeriods)
    % No valid frames => return NaNs
    warning('No valid mouse frames found. Returning NaNs.');
    return;
end
[~, longestPeriodIndex] = max([mouseFoundPeriods.Area]);
longestFrames = mouseFoundPeriods(longestPeriodIndex).PixelIdxList;

% Crop outputs to just the frames in that longest period
mouseCentroids  = mouseCentroids(longestFrames, :);
trackedVideo    = mouseEnhancedFrames(:, :, longestFrames);
mouseMaskMatrix = mouseMaskMatrix(:, :, longestFrames);
croppedVideo    = croppedVideo(:, :, longestFrames);

%% Compute forward speed from x-displacement
nValidFrames = size(mouseCentroids,1);
instForwardSpeed = nan(nValidFrames,1);

% We'll use a small window (velWin) ~ FRAMERATE/10 to measure displacement
velWin = floor(FRAMERATE / 10);
dx = diff(mouseCentroids(:,1));
winDisplacements = movsum(abs(dx), velWin, 'omitnan');
instForwardSpeed(1:length(winDisplacements)) = winDisplacements / (velWin / FRAMERATE);
meanSpeed = mean(instForwardSpeed, 'omitnan');

%% find periods when mouse has stopped
% stoppingFrames are frame indices, stoppingPeriods contain starts&stops
[stoppingFrames, stoppingStartStops] = detectStoppingOnBeam(instForwardSpeed, LOCOTHRESHOLD, FRAMERATE);

%% calculate speed of locomotion outside stopping periods
locoFrameList = find(~stoppingFrames);
meanSpeedLoco = mean(instForwardSpeed(locoFrameList), 'omitnan');
stdSpeedLoco = std(instForwardSpeed(locoFrameList), 'omitnan');

traverseDuration   = length(instForwardSpeed) / FRAMERATE;
end
