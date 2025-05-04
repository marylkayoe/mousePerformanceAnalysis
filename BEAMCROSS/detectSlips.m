function [slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations] = detectSlips(movementTrace, SLIPTHRESHOLD, DETRENDWINDOW)
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
    DETRENDWINDOW = 16; % rolling window, with 160 fps this is around 100ms
end

% default output values
slipEventStarts = [];
slipEventPeaks = [];
slipEventAreas = [];
slipEventDurations = [];
%% VALIDATIONS
% check that the movementTrace is not empty
if isempty(movementTrace)
    warning('Input movementTrace is empty. No slip events detected.');
    return;
end
% check that the movementTrace is a 1D array
if ~isvector(movementTrace)
    warning('Input movementTrace is not a 1D array. No slip events detected.');
    return;
end
% check that the movementTrace is a column vector, if not, transpose it
if isrow(movementTrace)
    movementTrace = movementTrace';
end

%% DETRENDING
% detrending the movement, so we look at big movements on top of ongoing
% movement
localMovementTrace = movmedian(movementTrace, DETRENDWINDOW);
movementTrace = movementTrace - localMovementTrace;

%% SLIP DETECTION
% -- 1) Create a logical mask of slip frames --
slipMask = movementTrace > SLIPTHRESHOLD;  % 1D array; 1 means "potential slip in this frame"

% -- 2) Cleaning up the slip mask --
%  'closing' merges small gaps up to 2 frames wide
% so that two slips separted by 2 frames of non-slip are merged into one
se = ones(1, 3);  % structuring element of length=3
slipMask = imclose(slipMask, se);

% remove slips shorter than 3 frames:
slipMask = bwareaopen(slipMask, 3);

% -- 3) Find contiguous slipping periods --
cc = bwconncomp(slipMask);  % returns connected-component info
nSLIPS = cc.NumObjects;  % number of slip events
if nSLIPS == 0
    warning('No slip events detected.');
    return;
end

% -- 4) Initialize output arrays --
slipEventStarts = nan(nSLIPS, 1);  % start frame of each slip
slipEventPeaks  = nan(nSLIPS, 1);  % peak value of each slip
slipEventAreas  = nan(nSLIPS, 1);  % area of each slip
slipEventDurations = nan(nSLIPS, 1);  % duration of each slip

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
