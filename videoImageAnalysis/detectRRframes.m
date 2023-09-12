function [rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames)
rrMask = [];
RRlengthFrames = nan;
startOfStillnessFrame =  find(stillFrames, 1, 'first');
endOfStillnessFrame =  find(stillFrames, 1, 'last');
diffsAfterStill(1:endOfStillnessFrame) = 0;
% speedBurstFrame(speedBurstFrame < find(stillFrames, 1, 'last')) = [];
[speedBurstAmp, speedBurstFrame, widths, peaks] = findpeaks(diffsAfterStill, "MinPeakHeight", 0.95, "MinPeakWidth", 10);
if isempty(speedBurstFrame)
    warning('No RR found after stillness, enterning largest peak HW, CHECK VALUE');
    [speedBurstAmp, speedBurstFrame, RRlengthFrames, peaks] = findpeaks(diffs, "MinPeakHeight", 0.95, "MinPeakWidth", 10);
    rrMask = zeros(size(stillFrames));
    rrMask(speedBurstFrame(end)-RRlengthFrames(end)/2:speedBurstFrame(end)+RRlengthFrames(end)/2) = 1;
    return;
else

    % looking at movement after burst half-width
    postBurstDiffs = diffsAfterStill;
    postBurstDiffs(1:speedBurstFrame(1) + widths(1)) = nan;
    fromStillDiffs = diffsAfterStill;
    fromStillDiffs(1:endOfStillnessFrame) = nan;
    [isPostMin P] = islocalmin(smooth(postBurstDiffs), 'FlatSelection', 'last');
    if(diffsAfterStill(find(isPostMin, 1, 'first'))) > 0.4
        
    else
    burstEndFrame = find(isPostMin, 1, 'first');
    end

    burstStartFrame =find (fromStillDiffs>0.4, 1, 'first');
    % burstEndFrame = find(postBurstDiffs<0.4, 1, 'first');

    RRlengthFrames = burstEndFrame-burstStartFrame;
    rrMask = zeros(size(stillFrames));
    rrMask(burstStartFrame:burstEndFrame) = 1;
end
end