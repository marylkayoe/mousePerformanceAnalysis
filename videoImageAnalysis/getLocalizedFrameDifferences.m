function diffs = getLocalizedFrameDifferences(videoMatrix, nFramesSmooth, FRAMERATE)

% Number of frames to use for smoothing
%nFramesSmooth = 5;  % or whatever number you want

% Smooth video frames
smoothedVideoMatrix = movmean(videoMatrix, nFramesSmooth, 3);

% Compute difference between each pair of consecutive frames in the smoothed video
diffImages = diff(smoothedVideoMatrix, 1, 3);

% High-pass filter to remove slow global illumination changes
Fs = FRAMERATE;  % Sampling frequency (depends on your video frame rate)
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

blankTH = FRAMERATE / 5;
% Finding peaks and their prominences
[~, locs, w, p] = findpeaks(diffs);

% Identifying outlier peaks based on a prominence threshold (modify the threshold value as necessary)
outlierPeakIdx = p > quantile(p, 0.99);  % Adjust the quantile value to control the sensitivity of the outlier detection
%shortPeakIdx = w < 5;
outlierEventsIdx = outlierPeakIdx;
% Removing outlier peak events
for i = find(outlierEventsIdx)'
    startIdx = max(1, locs(i) - blankTH);
    endIdx = min(length(diffs), locs(i) +blankTH);
    diffs(startIdx:endIdx) = 0;
end


diffs = diffs - min(diffs);
diffs = diffs ./ max (diffs);



end