function [nSLIPS slipIndex, slipLocs, meanProgressionSpeed] = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, CAMID, SLIPTH, MAKEPLOTS)

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

 [nSLIPS, slipIndex, slipLocs, meanProgressionSpeed] = analyzeSingleBBfile(dataFolder,fileName, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO);

