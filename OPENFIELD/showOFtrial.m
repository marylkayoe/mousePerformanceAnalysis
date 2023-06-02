function coordData = showOFtrial(dataFolder,EXPID, SAMPLEID, TASKID, FRAMERATE, PIXELSIZE)
% PIXELSIZE = how many mm one pixel is
if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end
OFfileID = '*.mp4';

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID);
fullFilePath = fullfile(dataFolder, fileName);
ofVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(fullFilePath);
[coordData mouseMask] = trackMouseInOF(double(videoMatrix));
coordData = coordData * PIXELSIZE;
[instSpeeds] = getMouseSpeedFromTraj(coordData, FRAMERATE, 10);
smoothedTraj = smoothdata(coordData(:, :), 'movmedian', 3);
f = plotOpenFieldTrial(smoothedTraj(1:end-1, :),instSpeeds, [], 0.2, 160);
 plotTrialSpeedData(instSpeeds, 0, FRAMERATE, strjoin({EXPID, '-',  SAMPLEID}));

 %displayMouseMasks(mouseMask, FRAMERATE);