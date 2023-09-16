function [stillFrames, diffs] = detectStillnessInVideo(videoMatrix, threshold, nFrames)

diffs = getFrameDifferences(videoMatrix, nFrames/10);

% defining start of trial with something happening in the frame, ignore
% everything before that
diffs = diffs / max(diffs);
[pks, locs] = findpeaks(diffs, 'MinPeakProminence', 0.3);
trialStartFrame = locs(1);
diffs(1:trialStartFrame+100) = nan;


% normalizing to the largest event
diffs = diffs / max(diffs);
diffs = diffs - min(diffs);

%need to skip the beginning of the recording when mouse / hands is not in the
%picture


slowFrames = zeros(size(diffs));

slowFrames = diffs < threshold;
%slowFrames(1:trialStartFrame) = 0;

stillChanges = diff(slowFrames);
stillStartFrames = find(stillChanges==1);
stillEndFrames = find(stillChanges == -1);
if stillEndFrames(1) < stillStartFrames(1)
    stillEndFrames(1) = [];
end
if stillStartFrames(end) > stillEndFrames(end)
    stillStartFrames(end) = [];
end
stillDurs = stillEndFrames-stillStartFrames;
%longStillIndex = find(stillDurs> nFrames, 1, 'first');
longStillIndex = find(stillDurs> nFrames, 1, 'last');
stillFrames = zeros(size(diffs));
stillFrames(stillStartFrames(longStillIndex):stillEndFrames(longStillIndex)) = 1;

end