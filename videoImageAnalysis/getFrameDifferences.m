function diffs = getFrameDifferences(videoMatrix, nFramesSmooth)

% Number of frames to use for smoothing
%nFramesSmooth = 5;  % or whatever number you want

% Smooth video frames
smoothedVideoMatrix = movmean(videoMatrix, nFramesSmooth, 3);

% Compute difference between each pair of consecutive frames in the smoothed video
diffImages = diff(smoothedVideoMatrix, 1, 3);

% Compute absolute difference values
absDiffImages = abs(diffImages);

% Sum absolute difference values over all pixels in each difference image
diffs = sum(sum(absDiffImages, 1), 2);

% Reshape diffs into a column vector
diffs = squeeze(diffs);

% 
% 
% % Compute difference between each pair of consecutive frames
% diffImages = diff(videoMatrix, 1, 3);
% 
% % Compute absolute difference values
% absDiffImages = abs(diffImages);
% 
% % Sum absolute difference values over all pixels in each difference image
% diffs = sum(sum(absDiffImages, 1), 2);
% 
% % Reshape diffs into a column vector
% diffs = squeeze(diffs);
% diffs(end)= 0;


end