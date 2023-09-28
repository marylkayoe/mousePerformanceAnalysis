function coordData = showOFtrial(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT ,PIXELSIZE, FRAMERATE)
% PIXELSIZE = how many mm one pixel is
if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('OFfileID', 'var')
    TIMEPOINT = '';
end


if ~exist('PIXELSIZE', 'var') 
    PIXELSIZE = 1;
end

DOWNSAMPLEFACTOR = 2; % how much videos are downsampled when converting to .mp4
PIXELSIZE = PIXELSIZE * DOWNSAMPLEFACTOR; 

% if ~exist('FRAMERATE', 'var') % note: FRAMERATE is read from the videos
%     FRAMERATE = 30;
% end
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT);
if isempty(fileName)
    coordData = [];
    warning('No video found and loaded');
    return;
end
fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo(fullFilePath, DOWNSAMPLEFACTOR); % newFilePath is with .mp4 ending


%% track the mouse
[coordData mouseMask] = trackMouseInOF(videoMatrix);
coordData = coordData * PIXELSIZE;
[instSpeeds] = getMouseSpeedFromTraj(coordData, FRAMERATE, FRAMERATE);
smoothedTraj = smoothdata(coordData(:, :), 'movmedian', 3);

fileIDstring = getFileIDfromFilename(fileName);
%% plot movement in arena and speed
f = plotOpenFieldTrial(smoothedTraj(1:end-1, :),instSpeeds, [], 0.2, 160, PIXELSIZE, fileIDstring);
 plotTrialSpeedData(instSpeeds, 40, FRAMERATE, strjoin({EXPID, '-',  SAMPLEID}));
displayBehaviorVideoMatrix(videoMatrix);
% this makes a video of the masked mouse
 displayBehaviorVideoMatrix(mouseMask);