function T = getTailMotionMetrics(videoMatrix, mouseFrames, mouseCentroids, mouseEntersFromRight, ...
    normMouseProbVals, noMouseProbCutoff, badFrameFracThresh)
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
mouseX = round(mouseCentroids(:, 1));
offsets = 0:mousePixelLength;
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

%% Tail motion trace
tailMovementTrace = getTailMotionTrace(postMouseVideoMatrix, croppedNoMouseProbValues);
badFrames = mean(badMask, 2) > badFrameFracThresh;
tailMovementTrace(badFrames) = nan;

T.tailMovementTrace = tailMovementTrace;
T.tailMotionSum = sum(tailMovementTrace, [], 'omitnan');
T.tailMotionMean = mean(tailMovementTrace, 'omitnan');
T.mousePixelLength = mousePixelLength;

T.postMouseVideoMatrix = postMouseVideoMatrix;
T.croppedNoMouseProbValues = croppedNoMouseProbValues;
T.cols = cols;
T.badFrames = badFrames;

end
