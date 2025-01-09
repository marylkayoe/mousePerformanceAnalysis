function [mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, stoppingPeriods, meanPosturalHeight, ...
    mouseMaskMatrix, trackedVideo, croppedVideo] = trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, FRAMERATE)
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
%
%   OUTPUTS:
%       mouseCentroids   : (nFrames x 2) array of mouse [x, y] centroids (in pixels).
%                          Frames where the mouse was not found are NaN.
%       forwardSpeeds    : (nFrames x 1) instantaneous forward speeds (pixels/sec).
%       meanSpeed        : (scalar) average speed (pixels/sec) across the detected frames.
%       traverseDuration : (scalar) time in seconds from the first to last frame
%                          where the mouse is detected continuously.
%       meanPosturalHeight : (scalar) average (mean) of mouseCentroids(:,2) after detection,
%                            giving a measure of postural height.
%       mouseMaskMatrix  : (height x width x nFrames) logical array marking where the
%                          mouse is detected in each frame.
%       trackedVideo     : (height x width x nFrames) double array, where each frame
%                          has been “ratio-ed” to the mean frame and annotated with
%                          a small white dot at the centroid location. Useful for
%                          quick visualization.
%       croppedVideo     : (height x width x nFrames) subset of the input video,
%                          further trimmed to only the frames during which the mouse
%                          was actually present. (Frames before/after are removed.)
%
%   ALGORITHM OVERVIEW:
%   1) Compute a mean frame and take the ratio (frame / meanFrame) for each frame
%      to highlight darker mouse pixels vs. background.
%   2) Threshold the ratio image (< 0.6) to create a binary mask of candidate
%      mouse regions (mouseMaskMatrix).
%   3) Morphologically close and remove small blobs from the mask to reduce noise.
%   4) For each frame, find all connected components >= MOUSESIZETH% of the frame area,
%      pick the largest blob as “the mouse,” and record its centroid.
%   5) Insert a small white circle (the centroid) into trackedVideo for visualization.
%   6) Identify the longest continuous span of frames in which the mouse is detected
%      (i.e., ignore large segments of NaNs), then crop all outputs to that timespan.
%   7) Compute forwardSpeeds from centroid displacement in the x-direction, smoothed
%      over a short window (~FRAMERATE/10). The meanSpeed is the average of these.
%   8) The traverseDuration is the length of the final valid frame segment in seconds.
%
%   EXAMPLE:
%       % Suppose we have a cropped video and we know the mouse is at least 5% of the frame
%       [centroids, fSpeeds, mSpeed, dur, posture, mask, tVid, cVid] = ...
%            trackMouseOnBeam(croppedVid, 5, 160);
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

% Basic video info
[imHeight, imWidth, nFrames] = size(croppedVideo);
frameArea = imHeight * imWidth;
minMouseArea = (MOUSESIZETH / 100) * frameArea;  % e.g. 5% => min area threshold

%% Preallocate
mouseCentroids = nan(nFrames, 2);
stoppingPeriods = cell(0);

% 1) Compute ratio image => highlight mouse as darker region
meanFrame = getMeanFrame(croppedVideo);
croppedVideoDouble = im2double(croppedVideo) + eps;  % small eps to avoid /0
meanFrameD         = im2double(meanFrame) + eps;
ratioMatrix        = croppedVideoDouble ./ meanFrameD;

% 2) Threshold ratio < 0.6 => binary mask. Then morphological cleanup
mouseMaskMatrix = (ratioMatrix < 0.6);
mouseMaskMatrix = imclose(mouseMaskMatrix, strel('disk', 3));
mouseMaskMatrix = bwareaopen(mouseMaskMatrix, 50); % remove very small noise

markerSize = 10;    % radius of the centroid marker (in pixels)

%% Loop through frames: find largest blob & mark centroid
for frameIndex = 1:nFrames
    maskFrame  = mouseMaskMatrix(:,:,frameIndex);
    ratioFrame = ratioMatrix(:,:,frameIndex);

    props = regionprops(maskFrame, 'Area', 'Centroid');
    if isempty(props)
        % No blobs => skip (NaNs remain in mouseCentroids).
        continue;
    end

    % Discard blobs smaller than minMouseArea
    largeBlobs = props([props.Area] >= minMouseArea);
    if isempty(largeBlobs)
        % All blobs too small => skip
        continue;
    end

    % Pick the largest blob
    [~, largestIndex] = max([largeBlobs.Area]);
    centroid = largeBlobs(largestIndex).Centroid;
    mouseCentroids(frameIndex, :) = centroid;

    % Insert a white circle on the ratioFrame around that centroid
    frameWithMarker = insertShape(ratioFrame, 'FilledCircle', ...
        [centroid(1), centroid(2), markerSize/2], ...
        'Color', [1 1 1], 'Opacity', 1);

    % Convert back to grayscale, store in ratioMatrix
    ratioMatrix(:,:,frameIndex) = rgb2gray(frameWithMarker);
end

trackedVideo = ratioMatrix;  % Each frame is "ratioed" + centroid marker

%% Identify the longest continuous segment of frames with a valid centroid
mouseFoundFrames = ~isnan(mouseCentroids(:,1));
mouseFoundFrames = imclose(mouseFoundFrames, strel('disk', 5));
mouseFoundFrames = bwareaopen(mouseFoundFrames, 10);

periods = regionprops(mouseFoundFrames, 'Area', 'PixelIdxList');
[~, longestPeriodIndex] = max([periods.Area]);
longestFrames = periods(longestPeriodIndex).PixelIdxList;

% Crop outputs to just the frames in that longest period
mouseCentroids  = mouseCentroids(longestFrames, :);
trackedVideo    = trackedVideo(:, :, longestFrames);
mouseMaskMatrix = mouseMaskMatrix(:, :, longestFrames);
croppedVideo    = croppedVideo(:, :, longestFrames);

%% Compute forward speed from x-displacement
nValidFrames = size(mouseCentroids,1);
forwardSpeeds = nan(nValidFrames,1);

% We'll use a small window (velWin) ~ FRAMERATE/10 to measure displacement
velWin = floor(FRAMERATE / 10);

% A quick way: measure distance between frames separated by velWin
% "frameDisplacements" is a difference between consecutive x positions:
%   pdist2() can be used, or simpler approach:
%   dx = mouseCentroids(2:end,1) - mouseCentroids(1:end-1,1);
%
% Below is an example using pdist2 but note we only need the diagonal offset:
frameDisplacements = pdist2(mouseCentroids(2:end,1), ...
                            mouseCentroids(1:end-1,1), 'euclidean');
winDisplacements   = diag(frameDisplacements, -velWin);

% Convert that displacement into speed (px/sec)
forwardSpeeds(1:length(winDisplacements)) = ...
    winDisplacements / (velWin / FRAMERATE);

meanSpeed = nanmean(forwardSpeeds);

% calculate stops 
LOCOTHRESHOLD = 100; % threshold for stopping; in pixels/sec

% define periods of stopping, as continuous segments below LOCOTHRESHOLD
stoppingFrames= forwardSpeeds < LOCOTHRESHOLD;
% morphological closing to connect small gaps, exclude too short periods
stoppingFrames = bwareaopen(imclose(stoppingFrames, strel('line', 5, 0)), 10);
% find contiguous regions of stopping
cc = bwconncomp(stoppingFrames);
% get the start and end frames of each stopping period
stoppingPeriods = cellfun(@(x) [x(1), x(end)], cc.PixelIdxList, 'UniformOutput', false);
% get the duration of each stopping period
stoppingDurations = cellfun(@(x) diff(x)+1, stoppingPeriods);


%% Additional Metrics
traverseDuration   = length(forwardSpeeds) / FRAMERATE;
meanPosturalHeight = nanmean(mouseCentroids(:, 2));

end
