function diffs = getLocalizedFrameDifferences(videoMatrix, nFramesSmooth)

% Number of frames to use for smoothing
%nFramesSmooth = 5;  % or whatever number you want

% Smooth video frames
smoothedVideoMatrix = movmean(videoMatrix, nFramesSmooth, 3);

% Compute difference between each pair of consecutive frames in the smoothed video
diffImages = diff(smoothedVideoMatrix, 1, 3);

% High-pass filter to remove slow global illumination changes
Fs = 200;  % Sampling frequency (depends on your video frame rate)
Fc = 0.1;  % Cut-off frequency
[b,a] = butter(6, Fc/(Fs/2), 'high');  % High-pass butterworth filter
diffImages = filter(b, a, diffImages, [], 3);


% Compute absolute difference values
absDiffImages = abs(diffImages);

% Apply threshold to exclude low-magnitude differences

% Calculate the 90th percentile of absDiffImages
threshold = prctile(absDiffImages(:), 99.9);

% Set all values less than the threshold to 0
absDiffImages(absDiffImages < threshold) = 0;




% Sum absolute difference values over all pixels in each difference image
diffs = sum(sum(absDiffImages, 1), 2);

% Reshape diffs into a column vector
diffs = squeeze(diffs);

diffs = diffs - min(diffs);
diffs = diffs ./ max (diffs);


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