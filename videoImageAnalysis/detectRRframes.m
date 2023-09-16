function [rrMask RRlengthFrames QC] = detectRRframes(diffs, stillFrames)
rrMask = [];
RRSTARTThreshold = 0.4;
QC = 1; % quality control measure, if 0 then a warning is added to plot

RRlengthFrames = nan;
startOfStillnessFrame =  find(stillFrames, 1, 'first');
endOfStillnessFrame =  find(stillFrames, 1, 'last');
diffsAfterStill = diffs;
% blank out movement info until end of stillness
if (isempty(endOfStillnessFrame))
    warning('No still period found! RR detection uncertain');
    QC = 0;
else
    diffsAfterStill(1:endOfStillnessFrame) = 0;
end
% find peaks in movement after the still period
[speedBurstAmp, speedBurstFrame, widths, peaks] = findpeaks(diffsAfterStill, "MinPeakHeight", 0.90, "MinPeakWidth", 10, 'NPeaks', 1);
% if there were no peaks in the assumed post-stillnes period (e.g.
% stillness was misplaced... take the overall highest peak and hope for the
% best

if isempty(speedBurstFrame)
    warning('No RR found after stillness, enterning largest peak HW, CHECK VALUE');
    [speedBurstAmp, speedBurstFrame, RRlengthFrames, peaks] = findpeaks(diffs, "MinPeakHeight", 0.90, "MinPeakWidth", 10);

    % rrMask(speedBurstFrame(end)-RRlengthFrames(end)/2:speedBurstFrame(end)+RRlengthFrames(end)/2) = 1;
    QC = 0;

    burstStartFrame =find (diffs(1:speedBurstFrame(1))<RRSTARTThreshold, 1, 'last');
    postBurstDiffs = diffs;
    postBurstDiffs(1:speedBurstFrame(1) + floor(RRlengthFrames(1)/2)) = nan;

    [isPostMin P] = islocalmin(smooth(postBurstDiffs), 'FlatSelection', 'last');
    if(diffsAfterStill(find(isPostMin, 1, 'first'))) > RRSTARTThreshold % if the movement at first minimum is too high
        burstEndFrame = find(isPostMin<RRSTARTThreshold, 1, 'first'); % we take the first point below the threshold
    else
        burstEndFrame = find(isPostMin, 1, 'first');
    end
    rrMask = zeros(size(stillFrames));
    rrMask(burstStartFrame:burstEndFrame) = 1;
    RRlengthFrames = burstEndFrame-burstStartFrame;

else

    % find the END of the RR:
    % looking at movement after burst half-width
    postBurstDiffs = diffsAfterStill;
    %blank out the movement until half-width
    postBurstDiffs(1:speedBurstFrame(1) + floor(widths(1)/2)) = nan;

    [isPostMin P] = islocalmin(smooth(postBurstDiffs), 'FlatSelection', 'last');
    if(diffsAfterStill(find(isPostMin, 1, 'first'))) > RRSTARTThreshold % if the movement at first minimum is too high
        burstEndFrame = find(isPostMin<RRSTARTThreshold, 1, 'first'); % we take the first point below the threshold
    else
        burstEndFrame = find(isPostMin, 1, 'first');
    end

    %% find START of RR
    % if we found no still period, we guess first point under threshold
    % before peak:
    if (isempty(endOfStillnessFrame))
        warning('Guessing start of RR at TH value');
        burstStartFrame =find (diffsAfterStill(1:speedBurstFrame(1))<RRSTARTThreshold, 1, 'last');
        QC = 0;
    else
        fromStillDiffs = diffsAfterStill;
        fromStillDiffs(1:endOfStillnessFrame) = nan;
        % pick the first point where movement rises above threshold after
        % the still period
        burstStartFrame =find (fromStillDiffs>RRSTARTThreshold, 1, 'first');
    end

    RRlengthFrames = burstEndFrame-burstStartFrame;
    rrMask = zeros(size(stillFrames));
    rrMask(burstStartFrame:burstEndFrame) = 1;

end