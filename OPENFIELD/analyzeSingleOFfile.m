function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, centerFraction, instSpeeds] = analyzeSingleOFfile(dataFolder, fileName, PIXELSIZE, MAKEPLOTS,BORDERLIMIT, DOWNSAMPLERATIO )
% runs the analysis for single trial based on filename
% note: the file has to be mp4; if not, it will be converted using
% DOWNSAMPLERATIO downsampling

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
% 
% [~, name, ext] = fileparts(fileName);
% if ~strcmp(ext, '.mp4')
%     warning('Provided filename indicates incorrect format (should be mp4).. seeking right version');
%     newFilePath = convertToMP4([dataFolder separator fileName]);
%     if isempty(newFilePath)
%         disp('Failed conversion, aborting');
%         return;
%     end
%     fileName = newFilePath;
% 
% end
% 



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
    displayBehaviorVideoMatrix(mouseMaskMatrix, indicatorString, [0 ; instSpeeds], isLocomoting);
    plotTrialSpeedData(instSpeeds, 40, FRAMERATE,fileIDstring);
    plotOpenFieldTrial(centroidCoords,[0 ; instSpeeds], centerFrames, BORDERLIMIT, FRAMERATE, PIXELSIZE, fileIDstring);
end
