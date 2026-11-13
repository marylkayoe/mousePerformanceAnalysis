function T = getTailMotionMetrics(videoMatrix, mouseFrames, mouseCentroids, mouseEntersFromRight, ...
    normMouseProbVals, noMouseProbCutoff, badFrameFracThresh, barPosition, barWidth)
%% getTailMotionMetrics
%   Computes tail motion behind the mouse by cropping each frame to a set of
%   columns extending from the mouse centroid backwards (towards the entry
%   side).
%
%   This is used to confirm that the noMouseProb weighting restricts the
%   tail-motion calculation to the intended region.
%
% INPUTS:
%   videoMatrix        : video (height x width x nFrames) or
%                        (height x width x channels x nFrames)
%   barPosition        : vertical position of the bar (scalar)
%   mouseFrames        : frame indices (vector) of the mouse traversal
%   mouseCentroids     : (nFrames x 2) centroid positions in pixel indices
%   mouseEntersFromRight : logical scalar (true if entry from right edge)
%   normMouseProbVals  : (width x nFrames) or (nFrames x width)
%
% OPTIONAL INPUTS:
%   noMouseProbCutoff    : scalar in [0..1], values below are set to 0 [0.85]
%   badFrameFracThresh   : fraction of columns allowed OOB before blanking [0.1]
%
% OUTPUT:
%   T : struct with fields:
%       .tailMovementTrace
%       .tailMotionSum
%       .tailMotionMean
%       .mousePixelLength
%       .postMouseVideoMatrix
%       .croppedNoMouseProbValues
%       .cols
%       .badFrames
%
% TODO: Handle missing tracking positions safely before cropping.
%   trackMouseOnBeam closes short gaps in its detection mask without filling
%   the corresponding NaN centroids, so the selected traversal can contain
%   missing positions. Guard nonfinite centroid X values before constructing
%   or using crop indices; skip video/probability crops for those frames and
%   mark their tail-motion measurements as NaN, preserving frame alignment.
%   Include these frames in badFrames. Also invalidate any motion measurements
%   that depend on a missing frame (check getTailMotionTrace's temporal
%   dependencies), so placeholder crops cannot introduce artificial motion.
%   Bounds clamping alone misses NaNs.

%% Defaults
if ~exist('noMouseProbCutoff', 'var') || isempty(noMouseProbCutoff)
    noMouseProbCutoff = 0.85;
end
if ~exist('badFrameFracThresh', 'var') || isempty(badFrameFracThresh)
    badFrameFracThresh = 0.1;
end

mouseFrames = mouseFrames(:);
nMouseFrames = numel(mouseFrames);

imHeight = size(videoMatrix, 1);
imWidth = size(videoMatrix, 2);

% if we don't have bar position, presume half the image height
if ~exist('barPosition', 'var') || isempty(barPosition)
    barPosition = round(imHeight / 2);
end


%% fix October 2026 - occasionally there are missing centroid values.
%% that shoulf be fixed in the tracking function, but as a temporary fix, interpolate across nans
%% up to 10 frames.

mouseX = mouseCentroids(:, 1); %note we only use the x coordinate in the tail function
% check if there are ANY nans in the mouseCentroids
if any(isnan(mouseCentroids(:)))
    warning('Mouse centroids contain NaNs. Interpolating across missing values.');
    maxMissingFrames = 10;

    mouseX(~isfinite(mouseX)) = NaN;

    [mouseX, interpolatedFrames] = fillmissing(mouseX, 'linear', ...
        'MaxGap', maxMissingFrames + 1, 'EndValues', 'none');

    mouseX = round(mouseX);

end




%% Input checks / orientation
% keep convention as width x nFrames
if size(normMouseProbVals, 1) ~= imWidth && size(normMouseProbVals, 2) == imWidth
    normMouseProbVals = normMouseProbVals.';
end
if size(normMouseProbVals, 1) ~= imWidth
    error('normMouseProbVals must be width x nFrames (or nFrames x width).');
end

% derived: columns with low mouseProb get higher noMouseProb weight
noMouseProbVals = 1 - normMouseProbVals;

% allow normMouseProbVals to be either full-length (all frames) or already
% cropped to mouseFrames
if size(normMouseProbVals, 2) == nMouseFrames
    probIdx = 1:nMouseFrames;
    probIsCropped = true;
elseif size(normMouseProbVals, 2) >= max(mouseFrames)
    probIdx = mouseFrames;
    probIsCropped = false;
else
    error('normMouseProbVals must match mouseFrames or full video length.');
end

%% Estimate mouse length in pixels
mousePixelLength = median(sum(normMouseProbVals(:, probIdx) > 0, 1), 'omitnan');

%% Columns behind the mouse (towards entry direction)
mouseX = round(mouseX);
offsets = 0:mousePixelLength + mousePixelLength*0.25;
dirSign = 2*mouseEntersFromRight - 1;

colsRaw = mouseX + dirSign * offsets;

badMask = colsRaw < 1 | colsRaw > imWidth;
cols = colsRaw;
cols(cols < 1) = 1;
cols(cols > imWidth) = imWidth;

nCols = size(cols, 2);

%% Crop the video + crop corresponding prob values
if ndims(videoMatrix) == 3
    postMouseVideoMatrix = zeros(imHeight, nCols, nMouseFrames, 'like', videoMatrix);
else
    postMouseVideoMatrix = zeros(imHeight, nCols, size(videoMatrix, 3), nMouseFrames, 'like', videoMatrix);
end

croppedNoMouseProbValues = zeros(nCols, nMouseFrames, 'like', noMouseProbVals);

for k = 1:nMouseFrames
    frameIdx = mouseFrames(k);

    if ndims(videoMatrix) == 3
        postMouseVideoMatrix(:, :, k) = videoMatrix(:, cols(k, :), frameIdx);
    else
        postMouseVideoMatrix(:, :, :, k) = videoMatrix(:, cols(k, :), :, frameIdx);
    end

    if probIsCropped
        croppedNoMouseProbValues(:, k) = noMouseProbVals(cols(k, :), k);
    else
        croppedNoMouseProbValues(:, k) = noMouseProbVals(cols(k, :), frameIdx);
    end
end

%% Cutoff so trunk-region columns contribute 0 weight
croppedNoMouseProbValues(croppedNoMouseProbValues < noMouseProbCutoff) = 0;


aboveBarVideoMatrix = postMouseVideoMatrix(1:barPosition, :, :);
underBarVideoMatrix = postMouseVideoMatrix(barPosition+barWidth:end, :, :);
T.underBarVideoMatrix = underBarVideoMatrix;
T.aboveBarVideoMatrix = aboveBarVideoMatrix;





%% Tail motion trace - total post-mouse motion
tailMovementTrace = bbtail.getTailMotionTrace(postMouseVideoMatrix, croppedNoMouseProbValues);
badFrames = mean(badMask, 2) > badFrameFracThresh;
tailMovementTrace(badFrames) = nan;

%% tail motion trace - above and under bar regions

tailMovementTraceAboveBar = bbtail.getTailMotionTrace(aboveBarVideoMatrix, croppedNoMouseProbValues);
tailMovementTraceUnderBar = bbtail.getTailMotionTrace(underBarVideoMatrix, croppedNoMouseProbValues, ...
    'verticalWeightMaxAt', 0.5);
tailMovementTraceAboveBar(badFrames) = nan;
tailMovementTraceUnderBar(badFrames) = nan;

verticalVideo = permute(postMouseVideoMatrix, [2 1 3]);

nRows = size(postMouseVideoMatrix, 1);
nFrames = size(postMouseVideoMatrix, 3);

rowWeights = sqrt(linspace(0, 1, nRows)');
verticalWeights = repmat(rowWeights, 1, nFrames);

verticalMotionTrace = bbtail.getTailMotionTrace( ...
    verticalVideo, verticalWeights, 'verticalWeightPower', 0);


T.tailMovementTraceAboveBar = tailMovementTraceAboveBar;
T.tailMovementTraceUnderBar = tailMovementTraceUnderBar;

T.verticalMotionTrace = verticalMotionTrace;

T.tailMovementTrace = tailMovementTrace;
T.tailMotionSum = sum(tailMovementTrace, [], 'omitnan');
T.tailMotionMean = mean(tailMovementTrace, 'omitnan');
T.mousePixelLength = mousePixelLength;

T.postMouseVideoMatrix = postMouseVideoMatrix;
T.croppedNoMouseProbValues = croppedNoMouseProbValues;
T.cols = cols;
T.badFrames = badFrames;

end
