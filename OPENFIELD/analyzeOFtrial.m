function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, instSpeeds] = analyzeOFtrial(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID, FRAMERATE, PIXELSIZE)

% PIXELSIZE = how many mm one pixel is

if ~exist('OFfileID', 'var')
    OFfileID = '*';
end

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

 [videoMatrix newFilePath] = readBehaviorVideo(fileName);
 [centroidCoords mouseMaskMatrix] = trackMouseInOF(videoMatrix);

 [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, instSpeeds] = getLocoMeasures(centroidCoords, FRAMERATE);