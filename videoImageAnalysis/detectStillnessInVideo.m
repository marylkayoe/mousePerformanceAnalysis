function [stillFrames, diffs] = detectStillnessInVideo(vidObj, threshold, nFrames)
diffs = getFrameDifferences(vidObj, 5);    
%diffs = videoFrameDifferences(vidObj);
    diffs = diffs / max(diffs);
    slowFrames = zeros(size(diffs));

    slowFrames = diffs < threshold;

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
longStillIndex = find(stillDurs> nFrames, 1, 'first');

stillFrames = zeros(size(diffs));
stillFrames(stillStartFrames(longStillIndex):stillEndFrames(longStillIndex)) = 1;

    % accept frames as "still" only if there are at least nFrames consecutive below threshold:
    % kernel = ones(1, nFrames);
    % convOutput = conv(double(stillFrames), kernel, 'same');
    % stillFrames = convOutput >= nFrames;
    % 
end