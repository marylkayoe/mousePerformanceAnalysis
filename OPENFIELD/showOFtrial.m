function coordData = showOFtrial(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID, FRAMERATE, PIXELSIZE)
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
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID);
if isempty(fileName)
    coordData = [];
    warning('No video loaded');
    return;
end
fullFilePath = fullfile(dataFolder, fileName);
[ofVideo newFilePath] = readBehaviorVideo(fullFilePath); % newFilePath is with .mp4 ending
videoMatrix = readVideoIntoMatrix(newFilePath);


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