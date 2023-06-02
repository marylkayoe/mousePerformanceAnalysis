function RRlengthFrames = showRightningTrial(dataFolder,EXPID, SAMPLEID, TASKID, FRAMERATE)

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

startThreshold = 0.05;
nFrameThreshold = FRAMERATE;

RRfileID = '*.mp4';

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, RRfileID);
fullFilePath = fullfile(dataFolder, fileName);
rrVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(fullFilePath);
% detecting still moment as the rightning should occur after 1 sec holding
[stillFrames, diffs] = detectStillnessInVideo(videoMatrix, startThreshold, nFrameThreshold);

[rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames);


titleString = strjoin({EXPID SAMPLEID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE) 'sek'});

figure; hold on;
showKeyFrames(videoMatrix, find(rrMask));
title (strjoin({titleString, ' RR frames: '}));


displayBehaviorVideo(rrVideo, diffs, rrMask, titleString);
figure; hold on; 
xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
plot(xAx, diffs);
plot(xAx, rrMask);
legend({'Diff', 'rightning'});
title (titleString);

