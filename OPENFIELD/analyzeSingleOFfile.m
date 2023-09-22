function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, centerFraction, instSpeeds] = analyzeSingleOFfile(dataFolder, fileName, PIXELSIZE, MAKEPLOTS,BORDERLIMIT, DOWNSAMPLERATIO )
% runs the analysis for single trial based on filename
% note: the file has to be mp4; if not, it will be converted using
% DOWNSAMPLERATIO downsampling; do not change, it should be 2 (default if
% no variable given)
% Borderlimit: fraction of arena  considered "border region"; e.g. 0.15
% dataFolder without trailing separator (/)
% PIXELSIZE = how many mm one pixel is
% filenamestructure: EXPID_SAMPLEID_TRIALID_CAMID_DATE_USERID.avi


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end


if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

if ~exist('DOWNSAMPLERATIO', 'var') % this variable is for development, do not change it
    DOWNSAMPLERATIO = 2;
end

if ~exist('BORDERLIMIT', 'var')
    BORDERLIMIT = 0.15;
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


[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo([dataFolder separator fileName], DOWNSAMPLERATIO);
[centroidCoords mouseMaskMatrix] = trackMouseInOF(videoMatrix);
centroidCoords = centroidCoords * PIXELSIZE;
fileIDstring = getFileIDfromFilename(fileName);
[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, isLocomoting] = getSpeedMeasures(centroidCoords, FRAMERATE, fileIDstring);

[centerFrames borderFrames centerFraction] = getCenterBorderFrames(centroidCoords, BORDERLIMIT);
isCenter = zeros(size(instSpeeds));
isCenter(centerFrames) = 1;


if MAKEPLOTS
    % note: padding speed array with zero since first frame does not have speed
    indicatorString = [fileIDstring ' with locomotion indicated'];
    %displayBehaviorVideoMatrix(mouseMaskMatrix, indicatorString, [0 ; instSpeeds], isLocomoting);
    plotTrialSpeedData(instSpeeds, LOCOTHRESHOLD, FRAMERATE,fileIDstring);
    plotOpenFieldTrial(centroidCoords,[0 ; instSpeeds], centerFrames, BORDERLIMIT, FRAMERATE, PIXELSIZE, fileIDstring);
end
