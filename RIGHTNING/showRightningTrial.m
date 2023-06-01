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
% detecting still moment as the rightning should occur after 1 sec holding
[stillFrames, diffs] = detectStillnessInVideo(rrVideo, startThreshold, nFrameThreshold);

[rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames);

titleString = strjoin({EXPID SAMPLEID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE) 'sek'});
figure; hold on;
displayBehaviorVideo(rrVideo, diffs, rrMask, titleString);
% figure; hold on; 
% xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
% plot(xAx, diffs);
% plot(xAx, rrMask);
% legend({'Diff', 'rightning'});
% title (titleString);
figure; hold on;
showKeyFrames(rrVideo, find(rrMask));
title (titleString);
