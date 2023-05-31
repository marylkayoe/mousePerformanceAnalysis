function RRlengthFrames = showRightningTrial(dataFolder,EXPID, SAMPLEID, TASKID, FRAMERATE)

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

startThreshold = 0.05;
nFrameThreshold = 30;

RRfileID = '*.avi';

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, RRfileID);
fullFilePath = fullfile(dataFolder, fileName);
rrVideo = readBehaviorVideo(fullFilePath);

[stillFrames, diffs] = detectStillnessInVideo(rrVideo, startThreshold, nFrameThreshold);
[speedBurstAmp, speedBurstFrame] = findpeaks(diffs, "MinPeakHeight", 0.99);
speedBurstFrame(speedBurstFrame < find(stillFrames, 1, 'last')) = [];
isMin = islocalmin(diffs);
minFrames = find(isMin);
burstEndFrameIndex = find(minFrames > speedBurstFrame(end), 1, 'first');
burstEndFrame = minFrames(burstEndFrameIndex);
burstStartFrame = minFrames(burstEndFrameIndex-1);
RRlengthFrames = burstEndFrame-burstStartFrame;
burstMask = zeros(size(stillFrames));
burstMask(burstStartFrame:burstEndFrame) = 1;
displayBehaviorVideo(rrVideo, stillFrames, burstMask);
figure; hold on; 
xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
plot(xAx, diffs);
plot(xAx, burstMask);
legend({'Diff', 'rightning'});
title (strjoin({EXPID SAMPLEID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE) 'sek'}));
