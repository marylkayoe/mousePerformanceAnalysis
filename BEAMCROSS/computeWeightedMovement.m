function normMovementTrace = computeWeightedMovement(videoMatrix, normMouseProbVals, SMOOTHFACTOR)
% QUANTIFYWEIGHTEDMOVEMENTCOLS
%   Computes frame-to-frame motion in a grayscale video, weighting each column
%   by how likely the mouse is present in that column (given in normMouseProbVals).
%   The in slip detection, the video matrix contains pixels in the region 
%   under the bar.
%
%   movementTrace = quantifyWeightedMovementCols(videoMatrix, normMouseProbVals)
%
% INPUTS:
%   videoMatrix      : 3D array (height x width x nFrames), grayscale
%   normMouseProbVals: 2D array (image width x nFrames),
%                      normMouseProbVals(c, k) = fraction of that column c
%                      which is mouse in frame k (0..1).
%   SMOOTHFACTOR    : (optional) smoothing factor for the movement trace, default = 5
%
% OUTPUT:
%   movementTrace : a 1D vector of length nFrames, where movementTrace(k)
%                   is the total (weighted) difference from frame k-1 to k.
%

if ~exist('SMOOTHFACTOR', 'var')
    SMOOTHFACTOR = 5; % smoothing factor for the movement trace
end

nFrames = size(normMouseProbVals, 2);

% We'll have one movement value per frame
movementTrace = zeros(nFrames, 1);

% The first frame has no "previous" frame to compare
movementTrace(1) = 0;
%% LOOP through all frames
for k = 2 : nFrames
    % Previous and current frames (convert to double for difference)
    prevFrame = im2double(videoMatrix(:,:,k-1));
    currFrame = im2double(videoMatrix(:,:,k));

    % 1) Pixel-wise absolute difference
    frameDifference = abs(currFrame - prevFrame);  % (height x width)

    % 2) Sum differences by column => 1D array of length = image width
    frameDiffTotal = sum(frameDifference, 1);  

    % 3) Column probabilities for current frame
    probCurrFrame = normMouseProbVals(:, k);    % a value for each column in the image
    probCurrFrame = probCurrFrame .^ 2;  % square to enhance high motion

    % the calculation of movementTrace(k) can be an oneliner:
    % movementTrace(k) = sum(frameDiffSum .* probCurrFrame');
    % but for claritys:
   
    weightedDiffForCols = frameDiffTotal .* probCurrFrame'; 
    % 5) Sum across columns => single movement measure for this frame
    movementTrace(k) = sum(weightedDiffForCols);

end

%% normalization by Median Absolute Deviation (MAD)
% This is a robust method to normalize the movement trace, which is
% less sensitive to outliers than the standard deviation.

% 1) Compute median
medVal = median(movementTrace);

% 2) Compute median absolute deviation
madVal = median(abs(movementTrace - medVal));

% 3) Convert MAD to approximate std (for normal distribution)
% The constant 1.4826 scales the MAD to approximate the standard deviation
% for a normal distribution. It is derived from the relationship between
% the MAD and the standard deviation for a normal distribution:
% σ ≈ MAD / 0.6745, where 0.6745 is the 75th percentile of the standard
% normal distribution. Thus, 1 / 0.6745 ≈ 1.4826.
sigma_base = 1.4826 * madVal;

% 4) Z-score using median-based baseline
normMovementTrace = (movementTrace - medVal) / sigma_base;

% smooth the trace
normMovementTrace = smooth(normMovementTrace, SMOOTHFACTOR);

end




