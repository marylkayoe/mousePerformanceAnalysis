function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, centerFraction] = analyzeSingleOFtrial(dataFolder,EXPID, SAMPLEID, TASKID,TIMEPOINT, TRIALID, CAMID, USERID, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO )
% runs the analysis for single trial based on experimental identifiers
% PIXELSIZE = how many mm one pixel is
% filenamestructure should be: EXPID_SAMPLEID_TRIALID_CAMID_DATE_USERID.avi
% CAMID TRIALID USERID DATE are currently ignored

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

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end

PIXELSIZE = PIXELSIZE * DOWNSAMPLERATIO;

BORDERLIMIT = 0.2;

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

if iscell(fileName)
    fileName = fileName{1};
end
fileIDstring = getFileIDfromFilename(fileName); % cleaned-up version of the file indicator for figures

[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo([dataFolder separator fileName], DOWNSAMPLERATIO);
[centroidCoords mouseMaskMatrix] = trackMouseInOF(videoMatrix);
centroidCoords = centroidCoords * PIXELSIZE;

[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, isLocomoting] = getSpeedMeasures(centroidCoords, FRAMERATE, fileIDstring);

[centerFrames borderFrames centerFraction] = getCenterBorderFrames(centroidCoords, BORDERLIMIT);
isCenter = zeros(size(instSpeeds));
isCenter(centerFrames) = 1;


if MAKEPLOTS
    % note: padding speed array with zero since first frame does not have speed
    indicatorString = [fileIDstring ' with centerFrames indicated'];
    displayBehaviorVideoMatrix(mouseMaskMatrix, indicatorString, [0 ; instSpeeds], isCenter);
    plotTrialSpeedData(instSpeeds, 40, FRAMERATE,fileIDstring);
    plotOpenFieldTrial(centroidCoords,[0 ; instSpeeds], centerFrames, BORDERLIMIT, FRAMERATE, PIXELSIZE, fileIDstring);
end
