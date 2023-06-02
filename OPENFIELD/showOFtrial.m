function coords = showOFtrial(dataFolder,EXPID, SAMPLEID, TASKID, FRAMERATE)

if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end
OFfileID = '*.avi';

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID);
fullFilePath = fullfile(dataFolder, fileName);
ofVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(filePath);
coords = trackMouseInOF(ofVideo);