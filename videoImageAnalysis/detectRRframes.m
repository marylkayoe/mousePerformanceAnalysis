function [rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames)
    [speedBurstAmp, speedBurstFrame, widths, peaks] = findpeaks(diffs, "MinPeakHeight", 0.99);
    speedBurstFrame(speedBurstFrame < find(stillFrames, 1, 'last')) = [];
    isMin = islocalmin(smooth(diffs), 'FlatSelection', 'last');
    minFrames = find(isMin);
    burstEndFrameIndex = find(minFrames > speedBurstFrame(end), 1, 'first');
    burstEndFrame = minFrames(burstEndFrameIndex);
    burstStartFrame = minFrames(burstEndFrameIndex-1);
    burstStartFrame = ceil(burstEndFrame - widths(end)*2)-1;

    RRlengthFrames = burstEndFrame-burstStartFrame;
    rrMask = zeros(size(stillFrames));
    rrMask(burstStartFrame:burstEndFrame) = 1;
end