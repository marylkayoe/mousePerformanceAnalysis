function outlierWindow = selectOptimalOutlierWindow(timeSeriesData, sampleRate)
   % this function can be used to find appropriate time window in time series data
   % for detecting outliers. Use with caution.
   % inputs:
   % timeSeriesData: 1D trajectory with no gaps (nans) in it

    % Perform a Fourier analysis to find the dominant frequency
    Fs = sampleRate; % Sampling frequency (in Hz)
    L = length(timeSeriesData); % Length of the signal
    Y = fft(timeSeriesData);
    P2 = round(abs(Y/L));
    halfIndex = round(L/2 + 1); % Round the result to the nearest integer
    P1 = P2(1:halfIndex);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;

  % Exclude the highest 1% of frequencies
  excludePercentage = 0.01; % Exclude 1% of highest frequencies
  excludeIndex = round((1 - excludePercentage) * length(f));

% Find the index of the maximum amplitude, excluding 0 Hz and the highest 1% frequencies
[~, idx] = max(P1(2:excludeIndex)); % Skip the 0 Hz frequency and high freq
dominantFrequency = f(idx + 1); % Add 1 to account for the skipped 0 Hz frequency

% Calculate the optimal outlier window based on the dominant frequency
outlierWindow = round(sampleRate / dominantFrequency);
end
