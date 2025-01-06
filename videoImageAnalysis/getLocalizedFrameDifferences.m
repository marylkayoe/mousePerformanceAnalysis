function diffs = getLocalizedFrameDifferences(videoMatrix, nFramesSmooth, FRAMERATE)
% GETLOCALIZEDFRAMEDIFFERENCES
% Applies:
%   (1) temporal smoothing,
%   (2) frame-to-frame differencing,
%   (3) high-pass filtering in time,
%   (4) absolute thresholding,
%   (5) outlier removal,
%   (6) normalization
% to produce a 1D "movement" metric over time.

    disp('Finding movement frames....');

    % STEP 1: Smooth the video over time dimension
    % This reduces short-term fluctuations but can blur quick events.
    smoothedVideoMatrix = movmean(videoMatrix, nFramesSmooth, 3);

    % STEP 2: Frame-to-frame differences along time
    diffImages = diff(smoothedVideoMatrix, 1, 3);

    % STEP 3: High-pass filter the difference to remove slow global changes
    Fs = FRAMERATE;  
    Fc = 0.1;   % cutoff freq in Hz
    [b,a] = butter(6, Fc/(Fs/2), 'high');
    diffImages = filter(b, a, diffImages, [], 3);

    % STEP 4: Absolute differences
    absDiffImages = abs(diffImages);

    % STEP 5: Threshold strong differences
    threshold = prctile(absDiffImages(:), 99.9);
    absDiffImages(absDiffImages < threshold) = 0;

    % Summation over all pixels in each difference frame
    diffs = squeeze(sum(sum(absDiffImages, 1), 2));

    disp('Removing spurious frames....');
    blankTH = floor(FRAMERATE / 5);

    % STEP 6: Outlier removal using findpeaks
    [~, locs, widths, prominences] = findpeaks(diffs);

    % Mark outlier peaks (above 99th percentile of prominence)
    outlierThreshold = quantile(prominences, 0.99);
    outlierPeakIdx   = prominences > outlierThreshold;

    % Zero out a window around these outlier events
    for iPeak = find(outlierPeakIdx)'
        startIdx = max(1, locs(iPeak) - blankTH);
        endIdx   = min(length(diffs), locs(iPeak) + blankTH);
        diffs(startIdx:endIdx) = 0;
    end

    % STEP 7: Normalize diffs to [0..1]
    diffs = diffs - min(diffs);
    diffs(1) = 0;  % not strictly necessary, but maybe you want the first to be 0
    diffs = diffs ./ max(diffs);
end



% function diffs = getLocalizedFrameDifferences(videoMatrix, nFramesSmooth, FRAMERATE)
% 
% % Number of frames to use for smoothing
% %nFramesSmooth = 5;  % or whatever number you want
% disp('Finding movement frames....');
% % Smooth video frames
% smoothedVideoMatrix = movmean(videoMatrix, nFramesSmooth, 3);
% 
% % Compute difference between each pair of consecutive frames in the smoothed video
% diffImages = diff(smoothedVideoMatrix, 1, 3);
% 
% % High-pass filter to remove slow global illumination changes
% Fs = FRAMERATE;  % Sampling frequency (depends on your video frame rate)
% Fc = 0.1;  % Cut-off frequency
% [b,a] = butter(6, Fc/(Fs/2), 'high');  % High-pass butterworth filter
% diffImages = filter(b, a, diffImages, [], 3);
% 
% 
% % Compute absolute difference values
% absDiffImages = abs(diffImages);
% 
% % Apply threshold to exclude low-magnitude differences
% 
% % Calculate the 90th percentile of absDiffImages
% threshold = prctile(absDiffImages(:), 99.9);
% 
% % Set all values less than the threshold to 0
% absDiffImages(absDiffImages < threshold) = 0;
% 
% 
% % Sum absolute difference values over all pixels in each difference image
% diffs = sum(sum(absDiffImages, 1), 2);
% 
% % Reshape diffs into a column vector
% diffs = squeeze(diffs);
% disp('Removing spurious frames....');
% blankTH = floor(FRAMERATE / 5);
% % Finding peaks and their prominences
% [~, locs, w, p] = findpeaks(diffs);
% 
% % Identifying outlier peaks based on a prominence threshold (modify the threshold value as necessary)
% outlierPeakIdx = p > quantile(p, 0.99);  % Adjust the quantile value to control the sensitivity of the outlier detection
% %shortPeakIdx = w < 5;
% outlierEventsIdx = outlierPeakIdx;
% % Removing outlier peak events
% for i = find(outlierEventsIdx)'
%     startIdx = max(1, locs(i) - blankTH);
%     endIdx = min(length(diffs), locs(i) + blankTH);
%     diffs(startIdx:endIdx) = 0;
% end
% 
% 
% diffs = diffs - min(diffs);
% diffs(1) = 0;
% diffs = diffs ./ max (diffs);
% 
% 
% 
% end