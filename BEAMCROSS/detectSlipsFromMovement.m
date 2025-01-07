function [slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations] = detectSlipsFromMovement(movementTrace, threshold, DETRENDWINDOW)
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

if ~exist('threshold', 'var')
    threshold = 2;
end

if ~exist('DETRENDWINDOW', 'var')
    DETRENDWINDOW = 16;
end

% default output values
slipEventStarts = [];
slipEventPeaks = [];
slipEventAreas = [];
slipEventDurations = [];


% detrending


winSize = 16;  % or choose based on typical posture timescale
localBase = movmedian(movementTrace, winSize);
detrended = movementTrace - localBase;

movementTrace = detrended;

% -- 1) Create a logical mask of slip frames --
slipMask = movementTrace > threshold;  % 1D logical array

% -- 2) Morphological operations on 1D data --
% For example, 'closing' merges small gaps up to 1-2 frames wide:
se = ones(1, 3);  % structuring element of length=3
slipMaskClosed = imclose(slipMask, se);

% Optionally remove very short slip bursts (fewer than 3 frames, say):
slipMaskClean = bwareaopen(slipMaskClosed, 3);
% bwareaopen in 1D: removes connected "true" regions with <3 frames

% -- 3) Find contiguous slip intervals --
cc = bwconncomp(slipMaskClean);  % returns connected-component info
slipEvents = struct('startFrame',{}, 'endFrame',{}, ...
    'peakValue',{}, 'area',{}, 'duration',{});

for s = 1 : cc.NumObjects
    theseFrames = cc.PixelIdxList{s};  % frames in the s-th slip
    startF = min(theseFrames);
    endF   = max(theseFrames);

    slipVals = movementTrace(theseFrames);
    peakVal  = max(slipVals);

    % "Area above threshold" => sum( (value - threshold) )
    areaVal = sum(slipVals - threshold);

    % Store in slipEvents
    slipEventStarts(s) = startF;
    slipEventPeaks(s)  = peakVal;
    slipEventAreas(s)  = areaVal;
    slipEventDurations(s) = endF - startF + 1;

end
end
