function [slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations, movementTrace, underBarCroppedVideo] = ...
    detectSlips(trackedVideo, mouseMaskMatrix, barTopCoord, barThickness, forwardSpeeds, SLIPTHRESHOLD, UNDERBARSCALE, DETRENDWINDOW)
%   Identify slip intervals in a 1D movement trace using:
%   1) threshold, default 2
%   2) morphological "closing" to merge tiny gaps
%   3) removal of short spurious slip bursts
%   4) contiguous-region analysis to measure slip area, etc.
%
%   slipEvents = detectSlipsWithMorph(movementTrace, threshold)
%
%   OUTPUT (slipEvents struct array):
%     .startFrame, .endFrame : indices bounding the slip episode
%     .peakValue             : max movementTrace value in that slip
%     .area                  : sum of (movementTrace - threshold) above threshold
%     .duration              : number of frames in the slip

if ~exist('SLIPTHRESHOLD', 'var')
    SLIPTHRESHOLD = 2; % for detecting smaller events, decrease this value
end

if ~exist('DETRENDWINDOW', 'var')
    DETRENDWINDOW = 64; % rolling window, with 160 fps this is 0.4 sec
end

if ~exist('UNDERBARSCALE', 'var')
    UNDERBARSCALE = 3; % scale factor for the under-bar region (related to bar thickness)
end

BARADJUSTVALUE = 3; % this shifts the position where slips are detected downwards... use if bar detection fails
SLIPSIZEFACTOR = 3; % minimum slip duration in frames
underBarSmoothFactor = 5; % smoothing for under-bar movement trace
normalizeMovementSpeed = true; % normalize by forward speed

% default output values
slipEventStarts = [];
slipEventPeaks = [];
slipEventAreas = [];
slipEventDurations = [];

disp('Detecting slips...');

%% --- Define "Under the Bar" Region ---
% We'll examine slip movements in a band below the bar region
% start: 5 px below midpoint of the bar
% end: UNDERBARSCALE x the bar thickness below the bar (+5 pixels)
underBarStart = round(barTopCoord + barThickness/2)+BARADJUSTVALUE;
underBarEnd   = round(barTopCoord + barThickness*UNDERBARSCALE)+BARADJUSTVALUE;
underBarCroppedVideo = trackedVideo( underBarStart:underBarEnd, :, : );


%% --- Probability Mask for Mouse Columns ---
% we weight them by how much of "mouse" each column has. So tail will not
% count so much.
% we only use the pixels above the bar
mouseMaskMatrix = mouseMaskMatrix(1: barTopCoord, :, :);
[normMouseProbVals, ~] = LF_computeMouseProbabilityMap(mouseMaskMatrix);

%% --- Quantify Weighted Movement  under the bar ---

movementTrace = LF_computeWeightedMovement(underBarCroppedVideo, normMouseProbVals, forwardSpeeds, underBarSmoothFactor, normalizeMovementSpeed);

%% DETRENDING
% detrending the movement
localMovementTrace = movmedian(movementTrace, DETRENDWINDOW);
movementTrace = movementTrace - localMovementTrace;

%% SLIP DETECTION
% -- 1) Create a logical mask of slip frames --
slipMask = movementTrace > SLIPTHRESHOLD;  % 1D array; 1 means "potential slip in this frame"

% -- 2) Cleaning up the slip mask --
%  'closing' merges small gaps up to 2 frames wide
% (two slips separted by >SLIPSIZEFACTOR frames of non-slip are merged into one)
se = ones(SLIPSIZEFACTOR,1);  % structuring element of length=3
slipMask = imclose(slipMask, se);

% remove slips shorter than 3 frames:
slipMask = bwareaopen(slipMask, SLIPSIZEFACTOR);

% -- 3) Find contiguous slipping periods --
cc = bwconncomp(slipMask);  % returns connected-component info
nSLIPS = cc.NumObjects;  % number of slip events
if nSLIPS == 0
    warning('No slip events detected.');
    return;
end

% -- 5) Loop through each slip event and calculate properties --
for slip = 1 : nSLIPS
    slipFrames = cc.PixelIdxList{slip};  % frame indices for the s-th slip
    startSlipFrame = min(slipFrames);
    endSlipFrame   = max(slipFrames);

    slipMagnitudes = movementTrace(slipFrames);
    peakSlipValue  = max(slipMagnitudes);

    % "Area above threshold" => sum( (value - threshold) )
    areaVal = sum(slipMagnitudes - SLIPTHRESHOLD);

    % collect the results into the output arrays
    slipEventStarts(slip) = startSlipFrame;
    slipEventPeaks(slip)  = peakSlipValue;
    slipEventAreas(slip)  = areaVal;
    slipEventDurations(slip) = endSlipFrame - startSlipFrame + 1;

end
end



function [normMouseProbVals, mouseProbMatrix] = LF_computeMouseProbabilityMap(mouseMaskMatrix)
% COMPUTEMOUSEPROBABILITYMAP Efficiently computes mouse pixel fraction per column per frame.
%
% INPUT:
%   mouseMaskMatrix: logical array (height x width x nFrames), indicating mouse pixels.
%
% OUTPUTS:
%   normMouseProbVals : (width x nFrames), fraction of mouse pixels per column.
%   mouseProbMatrix   : (height x width x nFrames), replicated probability images.

[imHeight, imWidth, nFrames] = size(mouseMaskMatrix);

% 1. Sum mouse-pixels along rows for all frames simultaneously
colSumAllFrames = squeeze(sum(mouseMaskMatrix, 1)); % size: [imWidth x nFrames]

% 2. Convert column-sums to fractions (dividing by height)
normMouseProbVals = colSumAllFrames / imHeight; % [imWidth x nFrames]

% 3. Replicate fractions down the rows to create mouse probability matrix
mouseProbMatrix = repmat(reshape(normMouseProbVals, [1, imWidth, nFrames]), imHeight, 1, 1);

end



function normMovementTrace = LF_computeWeightedMovement(videoMatrix, normMouseProbVals,forwardSpeeds,  SMOOTHFACTOR, NORMALIZESPEED, SPEEDWINDOW)
% COMPUTEWEIGHTEDMOVEMENT Computes weighted frame-to-frame motion efficiently.

if nargin < 4
    SMOOTHFACTOR = 5;
end

if nargin < 5
    NORMALIZESPEED = true;
end

if nargin < 6
    SPEEDWINDOW = 160;
end

% Convert video to double once
videoDouble = im2double(videoMatrix);

% Compute absolute difference across frames in one operation
videoDiff = abs(diff(videoDouble, 1, 3));  % size: [height x width x (nFrames-1)]

% Sum pixel differences column-wise (collapse rows)
colDiffSum = squeeze(sum(videoDiff, 1));   % size: [width x (nFrames-1)]

% Square the normMouseProbVals to enhance differences
weightedProbs = normMouseProbVals(:, 2:end).^2;  % size: [width x (nFrames-1)]

% Element-wise multiplication and sum columns for each frame (vectorized)
movementTrace = sum(colDiffSum .* weightedProbs, 1)'; % size: [(nFrames-1) x 1]

% Insert 0 at first frame since no prior frame
movementTrace = [0; movementTrace];

% Robust normalization using Median Absolute Deviation (MAD)
medVal = median(movementTrace, "omitnan");
madVal = median(abs(movementTrace - medVal), "omitnan");
sigma_base = 1.4826 * madVal;
normMovementTrace = (movementTrace - medVal) / sigma_base;

% Smooth the trace
normMovementTrace = smooth(normMovementTrace, SMOOTHFACTOR);

% speed-adjusted movement trace
if NORMALIZESPEED
normMovementTrace = normMovementTrace*SPEEDWINDOW ./ forwardSpeeds;
end

% make negative values zero
normMovementTrace(normMovementTrace < 0) = 0;

%normMovementTrace = movementTrace;

end
