function normMovementTrace = computeWeightedMovement(videoMatrix, normMouseProbVals, SMOOTHFACTOR)
% COMPUTEWEIGHTEDMOVEMENT Computes weighted frame-to-frame motion efficiently.

if nargin < 3
    SMOOTHFACTOR = 5;
end

[~, width, nFrames] = size(videoMatrix);

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
medVal = median(movementTrace);
madVal = median(abs(movementTrace - medVal));
sigma_base = 1.4826 * madVal;
normMovementTrace = (movementTrace - medVal) / sigma_base;

% Smooth the trace
normMovementTrace = smooth(normMovementTrace, SMOOTHFACTOR);

end
