function R = showRightningTrial(dataFolder,EXPID, SAMPLEID, TASKID)

startThreshold = 0.05;
nFrameThreshold = 30;

RRfileID = '*.avi';

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, RRfileID);

rrVideo = readBehaviorVideo(fileName);

stillFrames = detectStillnessInVideo(rrVideo, startThreshold, nFrameThreshold);

displayBehaviorVideo(rrVideo, stillFrames, stillFrames);

R = 1;