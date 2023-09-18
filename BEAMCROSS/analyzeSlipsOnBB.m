function [nSLIPS slipIndex, slipLocs, meanProgressionSpeed] = analyzeSlipsOnBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, CAMID, SLIPTH, MAKEPLOTS)

if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

if ~exist('SLIPTH', 'var')
    SLIPTH = 2;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

DOWNSAMPLERATIO = 4;
PIXELSIZE = PIXELSIZE * DOWNSAMPLERATIO;
CROPVIDEO = 1; % crop top and bottom, 1/4 each
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, [TIMEPOINT '_' CAMID]);
if isempty(fileName)
    R = [];
    warning('No video loaded');
    return;
end
if (iscell(fileName))
    fileName = fileName{1};
end
fileID = getFileIDfromFilename (fileName);

fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo(fullFilePath, DOWNSAMPLERATIO, CROPVIDEO); % newFilePath is with .mp4 ending
nFRAMES = length(videoMatrix);

[centroids instProgressionSpeeds isLocomoting mouseMaskMatrix blankedFrames]= trackMouseInBB(videoMatrix, PIXELSIZE, FRAMERATE );
   

% now track what happens under the bar.. crop only below bar
underBarVideoMatrix = cropVideoBelowBar(videoMatrix);
%blank frames without mouse
blankedUnderBarVideoMatrix = underBarVideoMatrix;
blankedUnderBarVideoMatrix(:, :, blankedFrames) = 0;



% probability of mouse being in a current position along the bar
[mouseProbVals mouseProbMatrix] = getMouseProbOnBeam(mouseMaskMatrix);
% get movement value weighted by mouse presence 
underBarDiffs = getHighProbFrameDifferences(blankedUnderBarVideoMatrix, mouseProbVals, FRAMERATE/10, SLIPTH);

% find peaks in the (zscored) movement under themouse
[pks, slipLocs, w, p] = findpeaks(underBarDiffs, 'MinPeakDistance', FRAMERATE/10);

%track the hand so we can omit those frames from slips
[isHandInFrame handFrameIdx handMaskMatrix] = trackHandInBB(videoMatrix, PIXELSIZE, FRAMERATE); 
% remove "slips" from data if hand was in the frame
[hf, idx] = intersect(slipLocs, handFrameIdx);
slipLocs(idx) = [];

nSLIPS = length(slipLocs);
meanProgressionSpeed = round(mean(instProgressionSpeeds, 'omitnan'));
blankedUnderBarDiffs = underBarDiffs;
blankedUnderBarDiffs(handFrameIdx) = [];
slipIndex = round(sum (blankedUnderBarDiffs));
if MAKEPLOTS
%show the frames with slip peaks
showKeyFrames(videoMatrix, slipLocs,  ['SLIP FRAMES in ' fileID ', ' CAMID]);
plotOpenFieldTrial(centroids,underBarDiffs, slipLocs, '', FRAMERATE, PIXELSIZE, fileID, ['SLIP PROBABILITY from ' CAMID]);
titlestring = ['Speed on BB from ' CAMID];
plotOpenFieldTrial(centroids,[0 instProgressionSpeeds'], slipLocs, '', FRAMERATE, PIXELSIZE, fileID, titlestring);
displayBehaviorVideoMatrix(mouseMaskMatrix, [fileID '-UBmov-SLIPPING'],blankedUnderBarDiffs, blankedUnderBarDiffs>SLIPTH, 0);
displayBehaviorVideoMatrix(videoMatrix, [fileID '-speed-SLIPPING'], instProgressionSpeeds, blankedUnderBarDiffs>SLIPTH, 0);
end


