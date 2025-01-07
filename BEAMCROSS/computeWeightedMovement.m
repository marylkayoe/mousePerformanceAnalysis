function normMovementTrace = computeWeightedMovement(videoMatrix, normMouseProbVals)
% QUANTIFYWEIGHTEDMOVEMENTCOLS
%   Computes frame-to-frame motion in a grayscale video, weighting each column
%   by how likely the mouse is present (using normMouseProbVals).
%
%   movementTrace = quantifyWeightedMovementCols(videoMatrix, normMouseProbVals)
%
% INPUTS:
%   videoMatrix      : 3D array (height x width x nFrames), grayscale
%   normMouseProbVals: 2D array (width x nFrames),
%                      normMouseProbVals(c, k) = fraction of that column c
%                      which is mouse in frame k (0..1).
%
% OUTPUT:
%   movementTrace : a 1D vector of length nFrames, where movementTrace(k)
%                   is the total (weighted) difference from frame k-1 to k.
%
% EXAMPLE:
%   [probCols, ~] = getMouseProbOnBeam(mouseMaskMatrix);
%   movTrace = quantifyWeightedMovementCols(myVideo, probCols);
%   plot(movTrace); title('Column-Weighted Motion');
%
% Author: (Your Name / Lab)

[~, width, nFrames] = size(videoMatrix);

% We'll have one movement value per frame
movementTrace = zeros(nFrames, 1);


% The first frame has no "previous" frame to compare
movementTrace(1) = 0;

for k = 2 : nFrames
    % Previous and current frames (convert to double for difference)
    prevFrame = im2double(videoMatrix(:,:,k-1));
    currFrame = im2double(videoMatrix(:,:,k));

    % 1) Pixel-wise absolute difference
    diffFrame = abs(currFrame - prevFrame);  % (height x width)

    % 2) Sum differences by column => 1D array of length = width
    colDiffSum = sum(diffFrame, 1);  % sums over rows

    % 3) Column probabilities for previous & current frames
    probPrev = normMouseProbVals(:, k-1);  % (width x 1)
    probCurr = normMouseProbVals(:, k);    % (width x 1)

    % Option A: Use only the previous frame’s probabilities
    colProb = probCurr;

    % Option B: Use an average of previous & current
    %colProb = (probPrev + probCurr) / 2;

    % 4) Weight each column's diff by a non-linear transformation of colProb
        nonLinearColProb = colProb .^ 2;  % Example: square the probabilities
        weightedDiffCols = colDiffSum .* (nonLinearColProb.');  % be sure to transpose prob if needed
    % 5) Sum across columns => single movement measure for this frame
    movementTrace(k) = sum(weightedDiffCols);


end

normMovementTrace = movementTrace;

%% normalization by MAD
if 1
% 1) Compute median
medVal = median(movementTrace);

% 2) Compute median absolute deviation
madVal = median(abs(movementTrace - medVal));

% 3) Convert MAD to approximate std (for normal distribution)
sigma_base = 1.4826 * madVal;

% 4) Z-score using median-based baseline
normMovementTrace = (movementTrace - medVal) / sigma_base;

% smooth the trace
normMovementTrace = smooth(normMovementTrace, 5);

end



end
