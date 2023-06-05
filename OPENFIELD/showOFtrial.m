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
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID);
fullFilePath = fullfile(dataFolder, fileName);
ofVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(fullFilePath);


%% track the mouse
[coordData mouseMask] = trackMouseInOF(double(videoMatrix));
coordData = coordData * PIXELSIZE;
[instSpeeds] = getMouseSpeedFromTraj(coordData, FRAMERATE, 10);
smoothedTraj = smoothdata(coordData(:, :), 'movmedian', 3);

%% plot movement in arena and speed
f = plotOpenFieldTrial(smoothedTraj(1:end-1, :),instSpeeds, [], 0.2, 160);
 plotTrialSpeedData(instSpeeds, 40, FRAMERATE, strjoin({EXPID, '-',  SAMPLEID}));

% this makes a video of the masked mouse
% displayMouseMasks(mouseMask, FRAMERATE);