function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds] = analyzeOFtrial(dataFolder,EXPID, SAMPLEID, TASKID,TIMEPOINT, TRIALID, CAMID, USERID, FRAMERATE, PIXELSIZE )

% PIXELSIZE = how many mm one pixel is
% filenamestructure: EXPID_SAMPLEID_TRIALID_CAMID_DATE_USERID.avi

if ~exist('CAMID', 'var') % CAMID is used when there are more than one camera file
    CAMID = '*';
end

if ~exist('TRIALID', 'var')
    TRIALID = '*';
end

if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = '*';
end

if ~exist('TASKID', 'var')
    TASKID = 'OF';
end

if ~exist('USERID', 'var')
    USERID = '*';
end

if ~exist('VIDEOTYPE', 'var')
    VIDEOTYPE = '.avi';
end


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

if (isunix)
    separator = '/';
else
    separator = '\';
end

%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, TRIALID, CAMID, USERID, VIDEOTYPE);
if isempty(fileName)
    coordData = [];
    warning('No video loaded');
    return;
end

 [videoMatrix newFilePath] = readBehaviorVideo([dataFolder separator fileName{1}]);
 [centroidCoords mouseMaskMatrix] = trackMouseInOF(videoMatrix);
 centroidCoords = centroidCoords * PIXELSIZE;
 
displayBehaviorVideoMatrix(mouseMaskMatrix, fileName);
[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds] = getSpeedMeasures(centroidCoords, FRAMERATE, fileName{1});
 %[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, instSpeeds] = getLocoMeasures(centroidCoords, FRAMERATE);