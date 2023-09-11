function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds] = analyzeSingleOFfile(dataFolder, fileName, FRAMERATE, PIXELSIZE, MAKEPLOTS )
% runs the analysis for single trial based on filename
% note: the file has to be mp4

% PIXELSIZE = how many mm one pixel is
% filenamestructure: EXPID_SAMPLEID_TRIALID_CAMID_DATE_USERID.avi


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

LOCOTHRESHOLD = 40;

meanSpeed = [];
maxSpeed = [];
locoSpeed = [];
totalDistance = [];
totalDistanceLocomoting = [];
meanSpeedLocomoting = [];
instSpeeds = [];

if (isunix)
    separator = '/';
else
    separator = '\';
end

[~, name, ext] = fileparts(fileName);
if ~strcmp(ext, '.mp4')
    warning('Provided filename indicates incorrect format (should be mp4).. seeking right version');
    newFilePath = convertToMP4([dataFolder separator fileName]);
    if isempty(newFilePath)
        disp('Failed conversion, aborting');
        return;
    end
    fileName = newFilePath;

end


% %% import the video file and make it into a grayscale matrix:
% fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, TRIALID, CAMID, USERID, VIDEOTYPE);
% if isempty(fileName)
%     coordData = [];
%     warning('No video loaded');
%     return;
% end

[videoMatrix newFilePath] = readBehaviorVideo(fileName);
[centroidCoords mouseMaskMatrix] = trackMouseInOF(videoMatrix);
centroidCoords = centroidCoords * PIXELSIZE;


[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, isLocomoting] = getSpeedMeasures(centroidCoords, FRAMERATE, fileName);
%[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, instSpeeds] = getLocoMeasures(centroidCoords, FRAMERATE);


if MAKEPLOTS
    % note: padding speed array with zero since first frame does not have speed
    %displayBehaviorVideoMatrix(mouseMaskMatrix, fileName, [0 ; instSpeeds], isLocomoting);
    BORDERLIMIT = 0.15;
    plotOpenFieldTrial(centroidCoords,[0 ; instSpeeds], [], BORDERLIMIT, FRAMERATE, PIXELSIZE);
    title(fileName);
    plotTrialSpeedData(instSpeeds, LOCOTHRESHOLD, FRAMERATE, fileName);
end
