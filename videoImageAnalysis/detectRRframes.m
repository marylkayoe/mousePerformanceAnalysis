function [rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames)
startOfStillnessFrame =  find(stillFrames, 1, 'first');
endOfStillnessFrame =  find(stillFrames, 1, 'last');
diffs(1:endOfStillnessFrame) = 0;
   % speedBurstFrame(speedBurstFrame < find(stillFrames, 1, 'last')) = [];
    [speedBurstAmp, speedBurstFrame, widths, peaks] = findpeaks(diffs, "MinPeakHeight", 0.95, "MinPeakWidth", 10);

    postBurstDiffs = diffs;
    postBurstDiffs(1:speedBurstFrame(1)) = nan;
    fromStillDiffs = diffs;
    fromStillDiffs(1:startOfStillnessFrame) = nan;
    isPostMin = islocalmin(smooth(postBurstDiffs), 'FlatSelection', 'last');
    burstEndFrame = find(isPostMin, 1, 'first');

    %isPreMin = islocalmin(smooth(diffs));
    burstStartFrame =find (fromStillDiffs>0.1, 1, 'first');
    burstEndFrame = find(postBurstDiffs<0.5, 1, 'first');

    RRlengthFrames = burstEndFrame-burstStartFrame;
    rrMask = zeros(size(stillFrames));
    rrMask(burstStartFrame:burstEndFrame) = 1;
end